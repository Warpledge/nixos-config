"""The Local Models page: the models llama-swap can serve on this machine
(lib/local-models.nix plus the machine's localModels block), the .gguf files
LM Studio downloaded, the GPU, a fit estimate for a model's tuning, presets,
and a live test that runs llama-server with the tuning before it's applied.
effective() mirrors lib/local-ai.nix, which the build uses."""

import fnmatch
import glob
import json
import os
import re
import shlex
import shutil
import socket
import subprocess
import sys
import threading
import time
import urllib.request

import gguf
import nixfile

MODELS_DIR = os.path.expanduser("~/.lmstudio/models")
#--- Each model's last test and the tuning it ran with: {id: {tuning, result, at}}
TESTS = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"),
                     "omni-settings", "local-model-tests.json")
LLAMA_SWAP = "http://127.0.0.1:8090"
#--- Kept in step with lib/local-ai.nix and lib/settings.nix
TUNING = ("context", "cache", "gpuLayers", "cpuMoe", "batch", "cacheRam", "fitTarget", "loadMode")
ADDED_DEFAULTS = {"context": 32768, "args": [], "think": {}, "fast": None}
CACHE_BYTES = {"f16": 2.0, "bf16": 2.0, "q8_0": 34 / 32, "q5_1": 24 / 32, "q5_0": 22 / 32,
               "q4_1": 20 / 32, "q4_0": 18 / 32, "iq4_nl": 18 / 32}
GB = 1024 ** 3
MB = 1024 ** 2
QUANT = re.compile(r"(UD-)?(I?Q\d(_[A-Z0-9]+)*|BF16|F16|F32|MXFP4)", re.I)
#--- A prompt of ~1500 tokens, so prompt speed is measured on more than a few tokens
TEST_PROMPT = ("Summarise the following notes in three sentences.\n\n" +
               "The quick brown fox jumps over the lazy dog while the farmer counts sheep in "
               "the meadow, and the river runs past the old mill towards the sea. " * 50)


def read_nix(flake, rel):
    with open(os.path.join(flake, rel)) as f:
        return nixfile.to_python(nixfile.parse(f.read()).root)


def catalog(flake):
    return read_nix(flake, "lib/local-models.nix")


def profiles(flake):
    return read_nix(flake, "lib/gpu-profiles.nix")


#--------------------------------------------------------------------#
#-- What the build does
#--------------------------------------------------------------------#
def entries(flake, local_models):
    """{id: (category, entry)} for the catalog's code and chat models plus the
    machine's added ones, before tuning."""
    cat = catalog(flake)
    out = {}
    for category in ("code", "chat"):
        for mid, entry in (cat.get(category) or {}).items():
            out[mid] = (category, entry)
    for mid, own in ((local_models or {}).get("models") or {}).items():
        if mid not in out and own.get("category") in ("code", "chat"):
            entry = {**ADDED_DEFAULTS, **{k: v for k, v in own.items() if k != "category"}}
            out[mid] = (own["category"], entry)
    return out


def measured(entry, profile, profs):
    """The profile's defaults with the model's tuned.<profile> on top."""
    if not profile or profile not in profs:
        return {}
    return {**(profs[profile].get("defaults") or {}), **((entry.get("tuned") or {}).get(profile) or {})}


def effective(entry, profile, profs, own):
    """The tuning lib/local-ai.nix gives a model, `own` being the machine's
    localModels.models entry for it."""
    base = measured(entry, profile, profs)
    own = own or {}
    if own.get("gpuLayers") == "auto":
        base = {k: v for k, v in base.items() if k not in ("gpuLayers", "cpuMoe")}
    t = {**base, **{k: own[k] for k in TUNING if k in own}}
    t.setdefault("context", entry.get("context", 32768))
    if "cache" not in t and entry.get("cache"):
        t["cache"] = entry["cache"]
    return t


def headroom(t, profile, profs):
    """MB llama-server's fit leaves free; None when offload is set by hand."""
    if "fitTarget" in t:
        return t["fitTarget"]
    if "cpuMoe" in t or t.get("gpuLayers") not in (None, "auto"):
        return None
    return profs[profile]["headroomMB"] if profile in profs else 2048


def flags(t, profile, profs):
    """llama-server flags for tuning `t`, as lib/local-ai.nix and llama-swap.nix
    build them (the model's own args come after)."""
    cache = t.get("cache", "q8_0")
    out = [f"-c {t['context']}", "-np 1", "-fa on", f"-ctk {cache}", f"-ctv {cache}", "--no-webui"]
    if t.get("gpuLayers") not in (None, "auto"):
        out.append(f"-ngl {t['gpuLayers']}")
    for key, flag in (("loadMode", "--load-mode"), ("cpuMoe", "--n-cpu-moe"), ("batch", "-ub"),
                      ("cacheRam", "--cache-ram")):
        if key in t:
            out.append(f"{flag} {t[key]}")
    fit = headroom(t, profile, profs)
    if fit is not None:
        out.append(f"--fit-target {fit}")
    return out


#--------------------------------------------------------------------#
#-- Files and GPU
#--------------------------------------------------------------------#
def find_file(entry):
    """The file llama-swap would load for `entry`, as its `find -iname | sort | head` does."""
    folder = os.path.join(MODELS_DIR, entry.get("dir", ""))
    try:
        names = sorted(n for n in os.listdir(folder)
                       if fnmatch.fnmatch(n.lower(), entry.get("match", "").lower()))
    except OSError:
        return None
    return os.path.join(folder, names[0]) if names else None


def size_of(path):
    return sum(os.path.getsize(p) for p in gguf.shards(path) if os.path.exists(p))


def suggest(path):
    """An id, name and file match for a file nobody lists yet."""
    stem = gguf.SHARD.sub("", os.path.basename(path))
    stem = re.sub(r"\.gguf$", "", stem, flags=re.I)
    q = QUANT.search(stem)
    if q and q.start() > 0:
        stem = stem[:q.start()].rstrip("-_.")  # the folder already says which file
    mid = re.sub(r"[^a-z0-9.]+", "-", stem.lower()).strip("-")
    name = re.sub(r"[-_]+", " ", stem).strip()
    m = gguf.SHARD.search(os.path.basename(path))
    match = (gguf.SHARD.sub("", os.path.basename(path)) + "-*-of-*.gguf") if m else os.path.basename(path)
    return mid, name, match


def architectures(server):
    """A test for whether llama-swap's llama.cpp (`server`'s libllama) knows a
    model architecture: its names sit in the library as C strings. None when
    there's no server to ask."""
    if not server:
        return None
    lib = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(server))), "lib", "libllama.so")
    try:
        with open(lib, "rb") as f:
            data = f.read()
    except OSError:
        return None
    # No leading NUL: the linker shares string tails, so "qwen2" can end another name
    return lambda arch: not arch or f"{arch}\0".encode() in data


def arch_of(path):
    try:
        return gguf.architecture(path)
    except (OSError, ValueError, KeyError):
        return ""


def scan(known, knows=None):
    """Every model file under ~/.lmstudio/models: {path, dir, file, bytes, quant,
    id, arch, supported}. `id` is the model listing it, from `known` ({id: entry}),
    else null; `knows` is architectures()."""
    out = []
    for path in sorted(glob.glob(os.path.join(MODELS_DIR, "*", "*", "*.gguf"))):
        if not gguf.is_model(path):
            continue
        folder = os.path.relpath(os.path.dirname(path), MODELS_DIR)
        owner = next((mid for mid, e in known.items() if find_file(e) == path), None)
        q = QUANT.search(os.path.basename(path))
        mid, name, match = suggest(path)
        arch = arch_of(path)
        out.append({"path": path, "dir": folder, "file": os.path.basename(path), "bytes": size_of(path),
                    "quant": q.group(0) if q else "", "id": owner, "arch": arch,
                    "supported": knows(arch) if knows else True,
                    "suggest": {"id": mid, "name": name, "match": match}})
    return out


def read_int(path):
    try:
        with open(path) as f:
            return int(f.read().strip(), 0)
    except (OSError, ValueError):
        return 0


def meminfo():
    out = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                key, value = line.split(":", 1)
                out[key] = int(value.split()[0]) * 1024
    except OSError:
        pass
    return out


def gpu(profs):
    """The GPU with the most memory: name ids, memory in bytes, discrete or
    unified, and the profile whose pciIds match."""
    best = None
    for dev in glob.glob("/sys/class/drm/card[0-9]*/device"):
        vram = read_int(f"{dev}/mem_info_vram_total")
        if not vram:
            continue
        gtt = read_int(f"{dev}/mem_info_gtt_total")
        pci = f"{read_int(f'{dev}/vendor'):04x}:{read_int(f'{dev}/device'):04x}"
        card = {"pci": pci, "vram": vram, "vramUsed": read_int(f"{dev}/mem_info_vram_used"),
                "gtt": gtt, "device": dev}
        if best is None or vram + gtt > best["vram"] + best["gtt"]:
            best = card
    mem = meminfo()
    if best is None:
        return {"pci": "", "vram": 0, "vramUsed": 0, "gtt": 0, "memory": "none", "profile": None,
                "ram": mem.get("MemTotal", 0), "ramAvailable": mem.get("MemAvailable", 0)}
    profile = next((p for p, v in profs.items() if best["pci"] in (v.get("pciIds") or [])), None)
    # An APU's carve-out is small next to the RAM it shares through GTT
    unified = profs[profile]["memory"] == "unified" if profile else best["vram"] < best["gtt"] / 2
    best.update(memory="unified" if unified else "discrete", profile=profile,
                ram=mem.get("MemTotal", 0), ramAvailable=mem.get("MemAvailable", 0))
    del best["device"]
    best["others"] = others(best)
    return best


def running():
    """Models llama-swap has loaded now; None when it isn't answering."""
    try:
        with urllib.request.urlopen(f"{LLAMA_SWAP}/running", timeout=2) as r:
            return json.loads(r.read()).get("running") or []
    except (OSError, ValueError):
        return None


def others(card):
    """VRAM other apps use (desktop, browser, wallpaper): the live figure while
    llama-swap holds no model, else the last one seen then."""
    path = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "omni-settings", "vram-others.json")
    if card["memory"] == "unified" or not card["vram"]:
        return 0
    if not running():
        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                json.dump(card["vramUsed"], f)
        except OSError:
            pass
        return card["vramUsed"]
    try:
        with open(path) as f:
            return int(json.load(f))
    except (OSError, ValueError):
        return 2 * GB


def vram_used():
    return max((read_int(p) for p in glob.glob("/sys/class/drm/card[0-9]*/device/mem_info_vram_used")),
               default=0)


#--------------------------------------------------------------------#
#-- Fit estimate
#--------------------------------------------------------------------#
def placement(m, t):
    """(GPU bytes, RAM bytes) for weights, KV cache and compute under tuning `t`."""
    n = m.layers - m.mtp_layers  # MTP layers stay unloaded
    loaded = m.weights - sum(m.layer_bytes.get(i, 0) for i in range(n, m.layers))
    ngl = t.get("gpuLayers")
    if ngl in (None, "all", "auto"):
        ngl = n + 1
    on_gpu = set(range(max(0, n - min(ngl, n)), n))
    cpu_moe = t.get("cpuMoe", 0)
    gpu = sum(m.layer_bytes.get(i, 0) - (m.expert_bytes.get(i, 0) if i < cpu_moe else 0) for i in on_gpu)
    if ngl > n:
        gpu += m.other_bytes - m.embed_bytes
    ram = loaded - gpu
    kv = m.kv_bytes_per_token(CACHE_BYTES.get(t.get("cache", "q8_0"), 2.0), t["context"]) * t["context"]
    share = len([i for i in m.attention_layers if i in on_gpu]) / max(1, len(m.attention_layers))
    batch = t.get("batch", 512)
    # Fitted to llama.cpp's Vulkan buffers on eclipse (Ornith, -ub 2048, 2026-10-30)
    compute = batch * m.embedding * 48 + 128 * MB if on_gpu else 0
    gpu += kv * share + compute
    ram += kv * (1 - share) + t.get("cacheRam", 8192) * MB
    return gpu, ram, {"weights": m.weights, "kv": kv, "compute": compute}


def budget(card, t, profile, profs):
    """Bytes the model may use on the GPU, after the headroom."""
    room = (t.get("fitTarget") or (profs[profile]["headroomMB"] if profile in profs else 2048)) * MB
    if card["memory"] == "unified":
        return card["vram"] + min(card["gtt"], card["ram"]) - room
    return card["vram"] - card.get("others", 0) - room


def auto_offload(m, t, card, profile, profs):
    """What llama-server's fit would roughly pick when offload isn't set: experts
    of the first N layers in RAM (MoE), or the most layers that fit (dense)."""
    limit = budget(card, t, profile, profs)
    if m.experts:
        for k in range(0, m.layers + 1):
            if placement(m, {**t, "cpuMoe": k})[0] <= limit:
                return {"cpuMoe": k}
        return {"cpuMoe": m.layers}
    for k in range(m.layers + 1, -1, -1):
        if placement(m, {**t, "gpuLayers": k})[0] <= limit:
            return {"gpuLayers": "all" if k > m.layers else k}
    return {"gpuLayers": 0}


def estimate(path, t, card, profile, profs):
    m = gguf.read(path)
    auto = headroom(t, profile, profs) is not None
    placed = {**t, **auto_offload(m, t, card, profile, profs)} if auto else t
    gpu, ram, parts = placement(m, placed)
    limit = budget(card, t, profile, profs)
    total = card["vram"] + (min(card["gtt"], card["ram"]) if card["memory"] == "unified" else 0)
    if card["memory"] == "unified":
        gpu, ram = gpu + ram, 0  # one pool
    free = total - card.get("others", 0)
    status = "fits" if gpu <= limit else "tight" if gpu <= free else "over"
    ram_limit = card["ram"] * 0.85
    return {"gpu": gpu, "gpuTotal": total, "gpuBudget": limit, "others": card.get("others", 0),
            "ram": ram, "ramTotal": card["ram"],
            "ramOver": card["memory"] != "unified" and ram > ram_limit, "status": status,
            "auto": auto, "picked": placed if auto else {}, "parts": parts,
            "model": {"layers": m.layers - m.mtp_layers, "moe": bool(m.experts),
                      "trainedContext": m.trained_context,
                      "arch": m.arch}}


def contexts(m, low=4096):
    """Context sizes to offer: powers of two up to what the model was trained on."""
    out, c = [], low
    top = m.trained_context or 32768
    while c < top:
        out.append(c)
        c *= 2
    return out + [top]


def presets(path, t, card, profile, profs, entry):
    """Tuning changes for Max Speed, Max Context and Auto (llama-server fits it).
    Measured is the profile's tuned values, when the model has some."""
    m = gguf.read(path)
    limit = budget(card, t, profile, profs)
    unified = card["memory"] == "unified"

    def fastest(at):
        base = {**at, "gpuLayers": "all"}
        base.pop("cpuMoe", None)
        if placement(m, base)[0] <= limit:
            return {"gpuLayers": "all"}
        off = auto_offload(m, {k: v for k, v in at.items() if k not in ("gpuLayers", "cpuMoe")},
                           card, profile, profs)
        return {"gpuLayers": "all", **off} if "cpuMoe" in off else off

    speed = {"context": t["context"], **fastest(t)}
    if not unified and not m.experts and speed.get("gpuLayers") != "all":
        speed["context"] = min(t["context"], 32768)
    best = t["context"]
    for c in contexts(m):
        trial = {**t, "context": c, "gpuLayers": "all", "cpuMoe": m.layers if m.experts else 0}
        if not m.experts:
            trial.pop("cpuMoe")
        if placement(m, trial)[0] <= limit:
            best = c
    reach = {"context": best, **fastest({**t, "context": best})}
    out = [{"id": "speed", "title": "Max Speed", "tuning": speed},
           {"id": "context", "title": "Max Context", "tuning": reach},
           {"id": "auto", "title": "Auto", "tuning": {"gpuLayers": "auto", "context": entry.get("context", 32768)}}]
    if measured(entry, profile, profs):
        out.insert(0, {"id": "measured", "title": "Measured", "tuning": None})
    return out


#--------------------------------------------------------------------#
#-- Live test
#--------------------------------------------------------------------#
def tests():
    try:
        with open(TESTS) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def last_test(mid, t):
    """The model's last test when it ran with tuning `t`, else None."""
    entry = tests().get(mid)
    return entry if entry and entry.get("tuning") == t else None


def remember(mid, t, result):
    data = tests()
    data[mid] = {"tuning": t, "result": result, "at": time.strftime("%Y-%m-%d %H:%M")}
    try:
        os.makedirs(os.path.dirname(TESTS), exist_ok=True)
        with open(TESTS, "w") as f:
            json.dump(data, f)
    except OSError:
        pass


def post(url, body=None, timeout=10):
    data = json.dumps(body).encode() if body is not None else b""
    req = urllib.request.Request(url, data=data, method="POST",
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read() or b"null")


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def say(line):
    print(line, file=sys.stderr, flush=True)


def event(kind, **fields):
    """A progress event for the editor's live view: a stderr line of "@" and JSON."""
    say("@" + json.dumps({"event": kind, **fields}))


def stream_reply(port, deadline):
    """Sends the test prompt with a streamed reply, emitting a tokens event as
    tokens arrive; returns llama-server's timings from the last chunk."""
    body = json.dumps({"messages": [{"role": "user", "content": TEST_PROMPT}], "max_tokens": 256,
                       "stream": True}).encode()
    req = urllib.request.Request(f"http://127.0.0.1:{port}/v1/chat/completions", data=body, method="POST",
                                 headers={"Content-Type": "application/json"})
    timings, n, first, last_sent = {}, 0, None, 0.0
    with urllib.request.urlopen(req, timeout=deadline) as r:
        for raw in r:
            line = raw.decode(errors="replace").strip()
            if not line.startswith("data:") or line == "data: [DONE]":
                continue
            try:
                chunk = json.loads(line[5:])
            except ValueError:
                continue
            timings = chunk.get("timings") or timings
            delta = ((chunk.get("choices") or [{}])[0].get("delta") or {})
            if delta.get("content") or delta.get("reasoning_content"):
                n += 1
                now = time.time()
                if first is None:
                    first = now
                    event("stage", stage="generate")
                if now - last_sent > 0.25:
                    rate = (n - 1) / (now - first) if now > first else 0
                    event("tokens", n=n, rate=round(rate, 1))
                    last_sent = now
    return timings


class TooBig(Exception):
    """llama-server ran out of memory loading a model."""


OOM = re.compile(r"out of memory|failed to allocate|unable to allocate|ErrorOutOfDeviceMemory", re.I)


def runnable(server, path):
    """Raises ValueError when `server` can't run the model in `path`."""
    if not server or not os.path.exists(server):
        raise ValueError("llama-server isn't available: turn on llama-swap and rebuild")
    knows, arch = architectures(server), arch_of(path)
    if knows and not knows(arch):
        raise ValueError(f"This llama.cpp build doesn't know the {arch} architecture yet, so "
                         "llama-swap can't run this model. LM Studio has its own, newer engine.")


def unload_swap():
    """Frees the GPU: llama-swap reloads its model the next time an app asks."""
    event("stage", stage="unload")
    try:
        post(f"{LLAMA_SWAP}/api/models/unload")
        say("Unloaded llama-swap's models")
        time.sleep(2)
    except OSError:
        pass


def test(server, path, t, entry, profile, profs):
    """Runs llama-server on `path` with tuning `t` and the model's args, measures
    peak VRAM, RAM and speed, then stops it. llama-swap's loaded models are
    unloaded first so the GPU is free. Progress goes to stderr as llama-server's
    log lines and event() lines."""
    runnable(server, path)
    unload_swap()
    try:
        return run_once(server, path, t, entry, profile, profs)
    except TooBig as e:
        raise ValueError(str(e)) from None


def run_once(server, path, t, entry, profile, profs):
    """One load, test prompt and measurement; TooBig when it runs out of memory."""
    card_total = max((read_int(p) for p in glob.glob("/sys/class/drm/card[0-9]*/device/mem_info_vram_total")),
                     default=0)
    ram_total = meminfo().get("MemTotal", 0)
    port = free_port()
    words = [w for a in flags(t, profile, profs) + list(entry.get("args") or []) for w in shlex.split(a)]
    cmd = [server, "-m", path, "--port", str(port), "--host", "127.0.0.1"] + words
    say("$ " + " ".join(shlex.quote(c) for c in cmd[1:]))
    base_vram, base_ram = vram_used(), meminfo().get("MemAvailable", 0)
    peak = {"vram": base_vram, "ram": base_ram}
    buffers, tail = [], []
    event("stage", stage="load")
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            stdin=subprocess.DEVNULL, text=True, errors="replace")

    def reader():
        for line in proc.stdout:
            line = line.rstrip()
            tail.append(line)
            del tail[:-30]
            if "buffer size" in line:
                buffers.append(line.split(":", 1)[-1].strip())
            say(line)

    threading.Thread(target=reader, daemon=True).start()

    #--- Memory twice a second for the live graph, until the test ends
    stop = threading.Event()

    def sampler():
        while not stop.is_set():
            vram, avail = vram_used(), meminfo().get("MemAvailable", peak["ram"])
            peak["vram"] = max(peak["vram"], vram)
            peak["ram"] = min(peak["ram"], avail)
            event("mem", vram=vram, vramTotal=card_total, ram=ram_total - avail, ramTotal=ram_total)
            stop.wait(0.5)

    threading.Thread(target=sampler, daemon=True).start()
    try:
        deadline = time.time() + 600
        while True:
            if proc.poll() is not None:
                time.sleep(0.2)  # the reader thread takes the last lines
                if any(OOM.search(line) for line in tail):
                    raise TooBig("Out of memory while loading:\n" + "\n".join(tail[-8:]))
                raise ValueError("llama-server stopped while loading:\n" + "\n".join(tail[-8:]))
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{port}/health", timeout=2) as r:
                    if r.status == 200:
                        break
            except OSError:
                pass
            if time.time() > deadline:
                raise ValueError("llama-server took over 10 minutes to load")
            time.sleep(0.5)
        say("Loaded; sending a test prompt")
        event("stage", stage="prompt")
        try:
            timings = stream_reply(port, 600)
        except OSError as e:
            raise ValueError(f"The test prompt failed: {e}") from None
    finally:
        stop.set()
        proc.terminate()
        try:
            proc.wait(10)
        except subprocess.TimeoutExpired:
            proc.kill()
    result = {"vramPeak": peak["vram"], "vramBefore": base_vram, "vramTotal": card_total,
              "ramUsed": max(0, base_ram - peak["ram"]),
              "tokensPerSecond": round(timings.get("predicted_per_second", 0), 1),
              "promptPerSecond": round(timings.get("prompt_per_second", 0), 1),
              "promptTokens": timings.get("prompt_n", 0), "buffers": buffers}
    say(f"{result['tokensPerSecond']} tok/s, prompt {result['promptPerSecond']} tok/s, "
        f"VRAM peak {peak['vram'] / GB:.1f} of {card_total / GB:.1f} GB")
    event("stage", stage="done")
    return result


#--------------------------------------------------------------------#
#-- Auto-Tune
#--------------------------------------------------------------------#
MARGIN = 512 * MB  # VRAM a fitting attempt leaves free at its peak
MAX_ATTEMPTS = 14  # 24 when several context caches are tried


class Enough(Exception):
    """The attempt limit was reached: the search keeps its best so far."""


def autotune(server, path, entry, base, goal, min_rate, card, profile, profs, caches=None):
    """Finds tuning by loading the model again and again: the least offload that
    fits (goal "speed", at base's context), or the largest context still writing
    min_rate tokens a second (goal "context"), then a bigger batch if it reads
    prompts faster. `caches` are the context cache types to search with (base's
    alone by default); the best across them wins. Returns {best, result,
    attempts}; emits an attempt event each."""
    runnable(server, path)
    m = gguf.read(path)
    layers = m.layers - m.mtp_layers
    unified = card["memory"] == "unified"
    caches = caches or [base.get("cache", "q8_0")]
    limit = MAX_ATTEMPTS if len(caches) == 1 else 24
    keep = {}
    attempts = []

    def attempt(t):
        if len(attempts) >= limit:
            raise Enough
        n = len(attempts) + 1
        event("attempt", n=n, tuning=t, status="running")
        try:
            r = run_once(server, path, t, entry, profile, profs)
            # Over the margin, Vulkan spills into shared memory and slows down
            status = "fits" if unified or r["vramPeak"] <= r["vramTotal"] - MARGIN else "tight"
        except TooBig:
            r, status = None, "too big"
        a = {"n": n, "tuning": t, "status": status, "result": r}
        attempts.append(a)
        event("attempt", n=n, tuning=t, status=status, rate=r and r["tokensPerSecond"],
              prompt=r and r["promptPerSecond"], vramPeak=r and r["vramPeak"])
        return a

    def estimate_k(context):
        guess = auto_offload(m, {**keep, "context": context}, card, profile, profs)
        if m.experts:
            return guess.get("cpuMoe", 0)
        return 0 if guess.get("gpuLayers") == "all" else layers - guess.get("gpuLayers", 0)

    def offload(context, floor=0, bias=0):
        """The fitting attempt with the least offload at `context`, else None.
        k counts what leaves the GPU: experts of k layers (MoE) or k layers (dense);
        `floor` is a k known to be needed (a smaller context's answer) and `bias` how
        far the estimate was off there."""
        t0 = {**keep, "context": context}
        if unified:
            a = attempt({**t0, "gpuLayers": "all"})
            return a if a["status"] == "fits" else None

        def tuning(k):
            if m.experts:
                return {**t0, "gpuLayers": "all", "cpuMoe": k}
            return {**t0, "gpuLayers": "all" if k == 0 else layers - k}

        k = max(floor, min(layers, estimate_k(context) + bias))
        fit, fail = None, floor - 1  # least k that fits, most k that doesn't
        a = attempt(tuning(k))
        if a["status"] == "fits":
            fit, best, step = k, a, 1
            while fit > floor:  # step down, further each time, until one fails
                k = max(fail + 1, fit - step)
                a = attempt(tuning(k))
                if a["status"] != "fits":
                    fail = k
                    break
                fit, best, step = k, a, step * 2
        else:
            fail, step, best = k, 1, None
            while fail < layers:  # step up until one fits
                k = min(layers, fail + step)
                a = attempt(tuning(k))
                if a["status"] == "fits":
                    fit, best = k, a
                    break
                fail, step = k, step * 2
            if best is None:
                return None
        while fit - fail > 1:  # then halve the gap
            k = (fit + fail) // 2
            a = attempt(tuning(k))
            if a["status"] == "fits":
                fit, best = k, a
            else:
                fail = k
        return best

    def search(cache):
        """The goal's best attempt with one context cache, else None."""
        nonlocal keep
        keep = {**{k: v for k, v in base.items() if k not in ("gpuLayers", "cpuMoe", "fitTarget")},
                "cache": cache}
        best = None
        if goal == "context":
            sizes = sorted({c for c in contexts(m) if c >= base["context"]} | {base["context"]})
            floor = bias = 0
            for c in sizes:
                a = offload(c, floor, bias)
                if a is None or a["result"]["tokensPerSecond"] < min_rate:
                    break
                best = a
                k = a["tuning"].get("cpuMoe")
                if k is None and a["tuning"].get("gpuLayers") not in (None, "all"):
                    k = layers - a["tuning"]["gpuLayers"]
                floor = k or 0
                bias = floor - estimate_k(c)
        else:
            best = offload(base["context"])
        return best

    #--- The goal's measure of a winner: speed, or context and then speed
    def score(a):
        r = a["result"]
        return r["tokensPerSecond"] if goal != "context" else (a["tuning"]["context"], r["tokensPerSecond"])

    #--- A smaller cache (later in `caches`) costs some quality, so it wins only by more
    #--- than run-to-run noise: more context, or over 5% faster
    def clearly_better(a, b):
        ra, rb = a["result"]["tokensPerSecond"], b["result"]["tokensPerSecond"]
        if goal == "context" and a["tuning"]["context"] != b["tuning"]["context"]:
            return a["tuning"]["context"] > b["tuning"]["context"]
        return ra > rb * 1.05

    best, note = None, ""
    try:
        for cache in caches:
            a = search(cache)
            if a is not None and (best is None or clearly_better(a, best)):
                best = a
        if best is None:
            if goal == "context":
                raise ValueError(f"At {base['context'] // 1024}K context it can't reach {min_rate} "
                                 "tokens a second here; lower the context or the speed wanted.")
            raise ValueError("It doesn't fit at this context even with everything in RAM; "
                             "lower the context.")
        #--- A bigger batch reads prompts faster, when it fits and replies don't slow
        if best["tuning"].get("batch", 512) < 2048:
            for size in (2048, 1024):
                a = attempt({**best["tuning"], "batch": size})
                if a["status"] == "fits":
                    r, b = a["result"], best["result"]
                    if r["promptPerSecond"] > b["promptPerSecond"] and \
                            r["tokensPerSecond"] >= b["tokensPerSecond"] * 0.95:
                        best = a
                    break
    except Enough:
        note = f"Stopped after {limit} attempts; this is the best found."
        fitting = [a for a in attempts if a["status"] == "fits"
                   and (goal != "context" or a["result"]["tokensPerSecond"] >= min_rate)]
        if best is None and not fitting:
            raise ValueError(f"Nothing fitted in {limit} attempts.") from None
        if fitting:
            top = max(fitting, key=score)
            best = top if best is None or score(top) > score(best) else best
    event("attempt", n=best["n"], tuning=best["tuning"], status="best")
    return {"best": best["tuning"], "result": best["result"], "note": note,
            "attempts": [{k: v for k, v in a.items() if k != "result"} | {
                "rate": a["result"] and a["result"]["tokensPerSecond"]} for a in attempts]}


#--------------------------------------------------------------------#
#-- Quality check
#--------------------------------------------------------------------#
#--- Each model's last check: {id: {q8_0, q4_0, basePpl, unreliable, at}}
QUALITY = os.path.join(os.path.dirname(TESTS), "local-model-quality.json")
#--- Full precision's predictions, which the compared runs read; ~2 GB, deleted after
KLD_BASE = os.path.expanduser("~/.cache/omni-settings/kld-base.bin")
SMALLER = {"f16": ["q8_0", "q4_0"], "bf16": ["q8_0", "q4_0"], "q8_0": ["q4_0"]}
#--- A Full score over this means the model reads plain text poorly (a chat model on
#--- raw Markdown), which inflates every difference
UNREADABLE_PPL = 100
STATS = {"kld": re.compile(r"Mean\s+KLD:\s+(-?[\d.]+)"),
         "sameTop": re.compile(r"Same top p:\s+([\d.]+)"),
         "pplRatio": re.compile(r"Mean PPL\(Q\)/PPL\(base\)\s*:\s+([\d.]+)")}
FINAL_PPL = re.compile(r"Final estimate: PPL = ([\d.]+)")


def verdict(kld):
    """Rules of thumb for mean KL divergence against full precision."""
    return ("No real difference" if kld < 0.01 else "Slightly different" if kld < 0.05
            else "Noticeably different" if kld < 0.1 else "Clearly worse")


def quality_text(flake):
    """The check's text: the repo's README and guides, plain English plus Markdown."""
    parts = [os.path.join(flake, "README.md")] + sorted(glob.glob(os.path.join(flake, "docs", "guide", "*.md")))
    out = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "omni-settings", "quality-text.txt")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        for p in parts:
            with open(p) as src:
                f.write(src.read() + "\n\n")
    return out


def perplexity_offload(t):
    """The offload flags llama-perplexity shares with llama-server, from tuning `t`."""
    out = []
    if t.get("gpuLayers") not in (None, "auto"):
        out += ["-ngl", str(t["gpuLayers"])]
    for key, flag in (("cpuMoe", "--n-cpu-moe"), ("loadMode", "--load-mode"), ("batch", "-ub")):
        if key in t:
            out += [flag, str(t[key])]
    return out


def run_perplexity(binary, args):
    """Runs llama-perplexity, its lines to stderr; its output, or TooBig/ValueError."""
    tail, lines = [], []
    proc = subprocess.Popen([binary] + args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            stdin=subprocess.DEVNULL, text=True, errors="replace")
    try:
        for line in proc.stdout:
            line = line.rstrip()
            lines.append(line)
            tail = (tail + [line])[-8:]
            say(line)
        code = proc.wait()
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(10)
            except subprocess.TimeoutExpired:
                proc.kill()
    if code != 0:
        if any(OOM.search(line) for line in lines):
            raise TooBig("Out of memory:\n" + "\n".join(tail))
        raise ValueError("llama-perplexity failed:\n" + "\n".join(tail))
    return "\n".join(lines)


def quality(server, path, t, flake):
    """Scores the context cache types against full precision on the same text
    (llama-perplexity's KL divergence), with the model's offload from tuning `t`."""
    runnable(server, path)
    binary = os.path.join(os.path.dirname(os.path.realpath(server)), "llama-perplexity")
    if not os.path.exists(binary):
        raise ValueError("llama-perplexity isn't beside llama-server in this llama.cpp build")
    os.makedirs(os.path.dirname(KLD_BASE), exist_ok=True)
    if shutil.disk_usage(os.path.dirname(KLD_BASE)).free < 4 * GB:
        raise ValueError("The check needs about 3 GB free in ~/.cache for a while")
    common = ["-m", path, "-f", quality_text(flake), "-c", "4096", "--chunks", "2", "-fa", "on"] \
        + perplexity_offload(t)
    out = {}
    card_total = max((read_int(p) for p in glob.glob("/sys/class/drm/card[0-9]*/device/mem_info_vram_total")),
                     default=0)
    ram_total = meminfo().get("MemTotal", 0)
    stop = threading.Event()

    def sampler():  # the editor's memory graph
        while not stop.is_set():
            event("mem", vram=vram_used(), vramTotal=card_total,
                  ram=ram_total - meminfo().get("MemAvailable", 0), ramTotal=ram_total)
            stop.wait(0.5)

    threading.Thread(target=sampler, daemon=True).start()
    try:
        event("stage", stage="base")
        event("quality", cache="f16", status="running")
        text = run_perplexity(binary, common + ["-ctk", "f16", "-ctv", "f16", "--kl-divergence-base", KLD_BASE])
        m = FINAL_PPL.search(text)
        out["basePpl"] = float(m.group(1)) if m else None
        out["unreliable"] = bool(out["basePpl"] and out["basePpl"] > UNREADABLE_PPL)
        event("quality", cache="f16", status="done", ppl=out["basePpl"])
        for cache in ("q8_0", "q4_0"):
            event("stage", stage=cache)
            event("quality", cache=cache, status="running")
            text = run_perplexity(binary, common + ["-ctk", cache, "-ctv", cache,
                                                    "--kl-divergence-base", KLD_BASE, "--kl-divergence"])
            stats = {k: float(r.search(text).group(1)) for k, r in STATS.items() if r.search(text)}
            if "kld" not in stats:
                raise ValueError(f"llama-perplexity printed no KL divergence for {cache}")
            stats["verdict"] = verdict(stats["kld"])
            out[cache] = stats
            event("quality", cache=cache, status="done", **stats)
    finally:
        stop.set()
        try:
            os.remove(KLD_BASE)
        except OSError:
            pass
    event("stage", stage="done")
    return out


def last_quality(mid):
    try:
        with open(QUALITY) as f:
            return json.load(f).get(mid)
    except (OSError, ValueError):
        return None


def remember_quality(mid, result):
    try:
        with open(QUALITY) as f:
            data = json.load(f)
    except (OSError, ValueError):
        data = {}
    data[mid] = {**result, "at": time.strftime("%Y-%m-%d %H:%M")}
    try:
        os.makedirs(os.path.dirname(QUALITY), exist_ok=True)
        with open(QUALITY, "w") as f:
            json.dump(data, f)
    except OSError:
        pass


def passing_caches(current, checked, kld_limit):
    """The current cache plus each smaller one the check passed within kld_limit."""
    if not checked or checked.get("unreliable"):
        return [current]
    return [current] + [c for c in SMALLER.get(current, [])
                        if c in checked and checked[c]["kld"] <= kld_limit]
