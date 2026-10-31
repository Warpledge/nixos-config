"""Reads a GGUF model file's header: the metadata and tensor table, not the
weights, for the Local Models page's fit estimate. Format:
https://github.com/ggml-org/ggml/blob/master/docs/gguf.md"""

import os
import re
import struct
from dataclasses import dataclass, field

#--- Metadata value types: struct format, or None for string (8) and array (9)
TYPES = {0: "B", 1: "b", 2: "H", 3: "h", 4: "I", 5: "i", 6: "f", 7: "?", 8: None, 9: None,
         10: "Q", 11: "q", 12: "d"}
#--- Arrays kept whole; others are skipped, keeping only their length
KEEP_ARRAYS = re.compile(r"\.(head_count_kv|head_count|sliding_window_pattern|recurrent_layers)$")
SHARD = re.compile(r"-(\d{5})-of-(\d{5})\.gguf$", re.I)
LAYER = re.compile(r"^blk\.(\d+)\.")


@dataclass
class Model:
    arch: str = ""
    layers: int = 0
    trained_context: int = 0
    embedding: int = 0
    vocab: int = 0
    heads: int = 0
    kv_heads: list = field(default_factory=list)  # per layer
    key_length: int = 0
    value_length: int = 0
    experts: int = 0
    experts_used: int = 0
    attention_layers: list = field(default_factory=list)  # indexes keeping a KV cache
    sliding_window: int = 0
    sliding_layers: list = field(default_factory=list)  # indexes using the window
    swa_key_value: int = 0  # key + value length on sliding layers, when it differs
    weights: int = 0  # bytes, every shard
    layer_bytes: dict = field(default_factory=dict)  # layer -> bytes
    expert_bytes: dict = field(default_factory=dict)  # layer -> bytes of its experts
    other_bytes: int = 0  # embeddings, output and norms outside the layers
    embed_bytes: int = 0  # token_embd, which llama.cpp keeps in RAM
    mtp_layers: int = 0  # last layers that only draft tokens (MTP), not loaded by default

    def kv_bytes_per_token(self, element_bytes, context):
        """KV cache bytes per token of context; sliding-window layers count only
        their window, spread over `context`."""
        total = 0.0
        for i in self.attention_layers:
            sliding = i in self.sliding_layers
            kv = self.swa_key_value if sliding and self.swa_key_value else self.key_length + self.value_length
            per = self.kv_heads[i] * kv * element_bytes
            if sliding and self.sliding_window and context > self.sliding_window:
                per *= self.sliding_window / context
            total += per
        return total


class Reader:
    def __init__(self, f):
        self.f = f

    def take(self, fmt):
        size = struct.calcsize("<" + fmt)
        return struct.unpack("<" + fmt, self.f.read(size))[0]

    def string(self):
        return self.f.read(self.take("Q")).decode("utf-8", "replace")

    def skip_string(self):
        self.f.seek(self.take("Q"), os.SEEK_CUR)

    def value(self, kind, key=""):
        if kind == 8:
            return self.string()
        if kind == 9:
            inner, count = self.take("I"), self.take("Q")
            if KEEP_ARRAYS.search(key) and inner != 8 and inner != 9:
                return [self.take(TYPES[inner]) for _ in range(count)]
            if inner == 8:
                for _ in range(count):
                    self.skip_string()
            elif inner == 9:
                raise ValueError("nested arrays aren't supported")
            else:
                self.f.seek(struct.calcsize("<" + TYPES[inner]) * count, os.SEEK_CUR)
            return count  # only the length, e.g. the vocabulary size
        if kind not in TYPES:
            raise ValueError(f"unknown metadata type {kind}")
        return self.take(TYPES[kind])


def header(path):
    """(metadata, [(name, offset)], data_start, file_size) of one file."""
    with open(path, "rb") as f:
        r = Reader(f)
        if f.read(4) != b"GGUF":
            raise ValueError(f"{os.path.basename(path)} isn't a GGUF file")
        version = r.take("I")
        if version < 2:
            raise ValueError(f"GGUF version {version} is too old")
        tensors, kvs = r.take("Q"), r.take("Q")
        meta = {}
        for _ in range(kvs):
            key = r.string()
            meta[key] = r.value(r.take("I"), key)
        infos = []
        for _ in range(tensors):
            name = r.string()
            dims = r.take("I")
            f.seek(8 * dims + 4, os.SEEK_CUR)  # dimensions and ggml type
            infos.append((name, r.take("Q")))
        align = meta.get("general.alignment", 32)
        start = f.tell()
        start += (-start) % align
        size = os.fstat(f.fileno()).st_size
    return meta, infos, start, size


def shards(path):
    """Every file of a split model, in order, from any one of them."""
    m = SHARD.search(path)
    if not m:
        return [path]
    count = int(m.group(2))
    return [SHARD.sub(f"-{i:05d}-of-{count:05d}.gguf", path) for i in range(1, count + 1)]


def read(path):
    """The Model in `path` (any shard of a split one). Tensor sizes are the gaps
    between their offsets, so no type table is needed."""
    model = Model()
    meta = {}
    for part in shards(path):
        m, infos, start, size = header(part)
        meta = meta or m
        ordered = sorted(infos, key=lambda t: t[1])
        for n, (name, offset) in enumerate(ordered):
            end = ordered[n + 1][1] if n + 1 < len(ordered) else size - start
            nbytes = end - offset
            model.weights += nbytes
            layer = LAYER.match(name)
            if layer:
                i = int(layer.group(1))
                model.layer_bytes[i] = model.layer_bytes.get(i, 0) + nbytes
                if "_exps." in name:
                    model.expert_bytes[i] = model.expert_bytes.get(i, 0) + nbytes
            else:
                model.other_bytes += nbytes
                if name.startswith("token_embd."):
                    model.embed_bytes += nbytes
    arch = meta.get("general.architecture", "")

    def get(key, default=0):
        return meta.get(f"{arch}.{key}", default)

    model.arch = arch
    model.layers = get("block_count")
    model.trained_context = get("context_length")
    model.embedding = get("embedding_length")
    model.vocab = meta.get("tokenizer.ggml.tokens", 0) or get("vocab_size")
    heads = get("attention.head_count")
    model.heads = max(heads) if isinstance(heads, list) else heads
    kv = get("attention.head_count_kv", model.heads)
    model.kv_heads = kv if isinstance(kv, list) else [kv] * model.layers
    head_dim = model.embedding // model.heads if model.heads else 0
    model.key_length = get("attention.key_length", head_dim)
    model.value_length = get("attention.value_length", head_dim)
    model.experts = get("expert_count")
    model.experts_used = get("expert_used_count")
    model.mtp_layers = get("nextn_predict_layers")
    #--- Hybrid models: only every n-th layer is full attention, the rest recurrent
    interval = get("full_attention_interval")
    recurrent = get("attention.recurrent_layers", None)
    if isinstance(recurrent, list):
        model.attention_layers = [i for i in range(model.layers) if not recurrent[i]]
    elif interval:
        model.attention_layers = [i for i in range(model.layers) if (i + 1) % interval == 0]
    else:
        model.attention_layers = [i for i in range(model.layers) if model.kv_heads[i]]
    model.sliding_window = get("attention.sliding_window")
    pattern = get("attention.sliding_window_pattern", None)
    if isinstance(pattern, list):
        model.sliding_layers = [i for i, on in enumerate(pattern) if on]
    elif isinstance(pattern, int) and pattern > 1:
        model.sliding_layers = [i for i in range(model.layers) if (i + 1) % pattern]
    swa = get("attention.key_length_swa") + get("attention.value_length_swa")
    model.swa_key_value = swa
    return model


def is_model(path):
    """False for vision projectors (mmproj) and other files llama-server can't load as a model."""
    name = os.path.basename(path).lower()
    if not name.endswith(".gguf") or "mmproj" in name:
        return False
    m = SHARD.search(name)
    return not m or m.group(1) == "00001"
