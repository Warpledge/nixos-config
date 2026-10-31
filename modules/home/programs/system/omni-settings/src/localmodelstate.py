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


def scan(known):
    """Every model file under ~/.lmstudio/models: {path, dir, file, bytes, quant,
    id}. `id` is the model listing it, from `known` ({id: entry}), else null."""
    out = []
    for path in sorted(glob.glob(os.path.join(MODELS_DIR, "*", "*", "*.gguf"))):
        if not gguf.is_model(path):
            continue
        folder = os.path.relpath(os.path.dirname(path), MODELS_DIR)
        owner = next((mid for mid, e in known.items() if find_file(e) == path), None)
        q = QUANT.search(os.path.basename(path))
        mid, name, match = suggest(path)
        out.append({"path": path, "dir": folder, "file": os.path.basename(path), "bytes": size_of(path),
                    "quant": q.group(0) if q else "", "id": owner,
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


def test(server, path, t, entry, profile, profs):
    """Runs llama-server on `path` with tuning `t` and the model's args, measures
    peak VRAM, RAM and speed, then stops it. llama-swap's loaded models are
    unloaded first so the GPU is free; llama-swap reloads on the next request."""
    if not server or not os.path.exists(server):
        raise ValueError("llama-server isn't available: turn on llama-swap and rebuild")
    try:
        post(f"{LLAMA_SWAP}/api/models/unload")
        say("Unloaded llama-swap's models")
        time.sleep(2)
    except OSError:
        pass
    port = free_port()
    words = [w for a in flags(t, profile, profs) + list(entry.get("args") or []) for w in shlex.split(a)]
    cmd = [server, "-m", path, "--port", str(port), "--host", "127.0.0.1"] + words
    say("$ " + " ".join(shlex.quote(c) for c in cmd[1:]))
    base_vram, base_ram = vram_used(), meminfo().get("MemAvailable", 0)
    peak = {"vram": base_vram, "ram": base_ram}
    buffers, tail = [], []
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
            elif re.search(r"error|failed|out of memory|offload|fitting", line, re.I):
                say(line)

    threading.Thread(target=reader, daemon=True).start()

    def sample():
        peak["vram"] = max(peak["vram"], vram_used())
        peak["ram"] = min(peak["ram"], meminfo().get("MemAvailable", peak["ram"]))

    try:
        deadline = time.time() + 600
        while True:
            sample()
            if proc.poll() is not None:
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
        done = {}

        def ask():
            try:
                done["reply"] = post(f"http://127.0.0.1:{port}/v1/chat/completions",
                                     {"messages": [{"role": "user", "content": TEST_PROMPT}],
                                      "max_tokens": 256}, timeout=600)
            except OSError as e:
                done["error"] = str(e)

        worker = threading.Thread(target=ask, daemon=True)
        worker.start()
        while worker.is_alive():
            sample()
            worker.join(0.5)
        if "error" in done:
            raise ValueError(f"The test prompt failed: {done['error']}")
        timings = (done.get("reply") or {}).get("timings") or {}
    finally:
        proc.terminate()
        try:
            proc.wait(10)
        except subprocess.TimeoutExpired:
            proc.kill()
    card_total = max((read_int(p) for p in glob.glob("/sys/class/drm/card[0-9]*/device/mem_info_vram_total")),
                     default=0)
    result = {"vramPeak": peak["vram"], "vramBefore": base_vram, "vramTotal": card_total,
              "ramUsed": max(0, base_ram - peak["ram"]),
              "tokensPerSecond": round(timings.get("predicted_per_second", 0), 1),
              "promptPerSecond": round(timings.get("prompt_per_second", 0), 1),
              "promptTokens": timings.get("prompt_n", 0), "buffers": buffers}
    say(f"{result['tokensPerSecond']} tok/s, prompt {result['promptPerSecond']} tok/s, "
        f"VRAM peak {peak['vram'] / GB:.1f} of {card_total / GB:.1f} GB")
    return result
