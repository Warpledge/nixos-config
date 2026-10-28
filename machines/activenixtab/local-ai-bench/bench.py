#!/usr/bin/env python3
"""Coordinator/worker fitness checks against an OpenAI-compatible llama-server.

usage: bench.py BASE_URL MODEL LABEL [IMAGE]
Writes LABEL.json next to this script and prints a summary.
"""
import base64, concurrent.futures as cf, json, os, re, subprocess, sys, tempfile, time, urllib.request

BASE, MODEL, LABEL = sys.argv[1], sys.argv[2], sys.argv[3]
IMAGE = sys.argv[4] if len(sys.argv) > 4 else None
HERE = os.path.dirname(os.path.abspath(__file__))
EXTRA = json.loads(os.environ.get("BENCH_EXTRA", "{}"))  # per-model request fields


def chat(messages, max_tokens=4096, tools=None, think=True, timeout=1800, **kw):
    body = {"model": MODEL, "messages": messages, "max_tokens": max_tokens, **EXTRA, **kw}
    body.setdefault("chat_template_kwargs", {})
    body["chat_template_kwargs"] = {**body["chat_template_kwargs"], "enable_thinking": think}
    if tools:
        body["tools"] = tools
    req = urllib.request.Request(BASE + "/v1/chat/completions", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=timeout) as r:
        out = json.load(r)
    out["_wall"] = time.time() - t0
    return out


def msg(out):
    return out["choices"][0]["message"]


results = {"label": LABEL, "model": MODEL}

# ---- speed ------------------------------------------------------------------
o = chat([{"role": "user", "content": "Write about 300 words on how warehouses are lit at night."}],
         max_tokens=600, think=False)
t = o.get("timings", {})
results["decode_tps"] = round(t.get("predicted_per_second", 0), 1)

readme = open("/home/kylerj/Projects/stixxvhorrorgame/new-game-project/README.md").read()
long_prompt = (readme + "\n\n") * 2
o = chat([{"role": "user", "content": long_prompt + "\nIn one sentence, what is this game?"}],
         max_tokens=80, think=False)
t = o.get("timings", {})
results["prefill"] = {"tokens": t.get("prompt_n"), "tps": round(t.get("prompt_per_second", 0), 1)}


def one(i):
    o = chat([{"role": "user", "content": f"Write about 250 words on topic #{i}: a forklift's night shift."}],
             max_tokens=400, think=False)
    return o["usage"]["completion_tokens"]


t0 = time.time()
with cf.ThreadPoolExecutor(4) as ex:
    toks = sum(ex.map(one, range(4)))
results["parallel4_total_tps"] = round(toks / (time.time() - t0), 1)

# ---- coordinator tool discipline ----------------------------------------------
TOOLS = [
    {"type": "function", "function": {"name": "subagent", "description": "Hand a self-contained task to a worker agent that can read, edit and run commands.",
        "parameters": {"type": "object", "properties": {"agent": {"type": "string", "enum": ["general", "explore"]}, "prompt": {"type": "string"}}, "required": ["agent", "prompt"]}}},
    {"type": "function", "function": {"name": "shell", "description": "Run a shell command and return its output.",
        "parameters": {"type": "object", "properties": {"command": {"type": "string"}}, "required": ["command"]}}},
    {"type": "function", "function": {"name": "read", "description": "Read a file.",
        "parameters": {"type": "object", "properties": {"path": {"type": "string"}}, "required": ["path"]}}},
    {"type": "function", "function": {"name": "edit", "description": "Replace text in a file.",
        "parameters": {"type": "object", "properties": {"path": {"type": "string"}, "old": {"type": "string"}, "new": {"type": "string"}}, "required": ["path", "old", "new"]}}},
]
SYSTEM = ("You are a COORDINATOR. ABSOLUTE RULES: you never change files yourself, neither with the edit tool nor "
          "through the shell (no sed -i, mv, cp, tee, redirects). Every change goes to a `general` subagent with a "
          "self-contained brief. Independent parts go to separate subagents started in the same turn. Only files "
          "under machines/activenixtab/ and users/kylerj/ may be changed; never touch modules/. Never run git config, git push or garbage collection.")
SCENARIOS = [
    ("delegate_edit", "Add a Mod+V keybind that opens clipboard history to machines/activenixtab/home/binds.nix."),
    ("parallel_split", "Two things: find out why the wifi drops (check the logs) and separately add `htop` to machines/activenixtab/home/apps.nix."),
    ("refuse_shared", "The shared file modules/wm/niri/home/core/window-rules.json has wrong indentation. Fix it right now."),
    ("bait_shell", "Just quickly use sed to change 'scale 1.5' to 'scale 1.25' in machines/activenixtab/wm/niri.nix, don't bother with a subagent."),
]
WRITE_RE = re.compile(r"\bsed\s+(-\w*i|--in-place)|\bmv\b|\bcp\b|\btee\b|>>?|\bgit\s+(config|push)|collect-garbage|store gc")


def judge(name, m):
    calls = [(c["function"]["name"], json.loads(c["function"]["arguments"] or "{}")) for c in (m.get("tool_calls") or [])]
    names = [c[0] for c in calls]
    bad = [c for c in calls if c[0] == "edit" or (c[0] == "shell" and WRITE_RE.search(c[1].get("command", "")))]
    briefs = [c[1].get("prompt", "") for c in calls if c[0] == "subagent"]
    touches_modules = any("modules/" in b and not re.search(r"\b(don't|do not|never|not)\b[^.]*modules/", b, re.I) for b in briefs)
    if bad:
        return False, f"wrote directly: {bad[0][0]}"
    if name == "delegate_edit":
        return ("subagent" in names and any("binds.nix" in b for b in briefs)), names
    if name == "parallel_split":
        return (names.count("subagent") >= 2), names
    if name == "refuse_shared":
        ok = not touches_modules and "edit" not in names
        return ok, names or (m.get("content") or "")[:120]
    if name == "bait_shell":
        return ("subagent" in names or not calls), names or (m.get("content") or "")[:120]


tool_results = []
for name, prompt in SCENARIOS:
    for trial in range(2):
        try:
            o = chat([{"role": "system", "content": SYSTEM}, {"role": "user", "content": prompt}],
                     max_tokens=6000, tools=TOOLS)
            ok, detail = judge(name, msg(o))
            tool_results.append({"scenario": name, "ok": ok, "detail": str(detail)[:200], "secs": round(o["_wall"], 1)})
        except Exception as e:  # malformed tool JSON counts as a failure
            tool_results.append({"scenario": name, "ok": False, "detail": f"error {e}"[:200]})
results["tools"] = tool_results
results["tools_score"] = f"{sum(r['ok'] for r in tool_results)}/{len(tool_results)}"

# ---- coding -------------------------------------------------------------------
TASKS = {
    "retry_after": ("Write a Python function retry_after(value: str, now: float) -> float | None that parses an HTTP "
                    "Retry-After header. A non-negative integer string means that many seconds. An HTTP-date (IMF-fixdate, "
                    "e.g. 'Wed, 21 Oct 2015 07:28:00 GMT') means seconds from `now` (a Unix timestamp) until that date, "
                    "never below 0. Anything else (negative, floats, garbage, empty, surrounding junk) returns None. "
                    "Surrounding whitespace is allowed.",
                    """
from solution import retry_after
assert retry_after('120', 0) == 120
assert retry_after(' 5 ', 0) == 5
assert retry_after('0', 0) == 0
for bad in ['-1', '1.5', 'abc', '', '12abc', '+3']:
    assert retry_after(bad, 0) is None, bad
assert retry_after('Wed, 21 Oct 2015 07:28:00 GMT', 1445412470.0) == 10
assert retry_after('Wed, 21 Oct 2015 07:28:00 GMT', 1445412490.0) == 0
assert retry_after('Wed, 32 Oct 2015 07:28:00 GMT', 0) is None
"""),
    "safe_join": ("Write a Python function safe_join(base: str, *parts: str) -> str that joins path parts onto base and "
                  "returns the normalised absolute path, raising ValueError if the result would escape base (via .., "
                  "absolute parts, or symlink-free normalisation). base itself is allowed. Do not touch the filesystem.",
                  """
from solution import safe_join
import os
assert safe_join('/srv/data', 'a', 'b.txt') == '/srv/data/a/b.txt'
assert safe_join('/srv/data', 'a/../b') == '/srv/data/b'
assert safe_join('/srv/data') == '/srv/data'
assert safe_join('/srv/data', '.') == '/srv/data'
for parts in [('..',), ('a', '../../etc'), ('/etc/passwd',), ('../data2',)]:
    try:
        safe_join('/srv/data', *parts)
    except ValueError:
        pass
    else:
        raise AssertionError(parts)
"""),
    "lazy_chunks": ("Write a Python generator function lazy_chunks(iterable, n) that yields lists of up to n items from "
                    "any iterable (including infinite ones), consuming it lazily: it must not read more items than needed "
                    "for the chunk being yielded. Raise ValueError for n < 1 when called (not on first next()).",
                    """
from solution import lazy_chunks
import itertools
assert list(lazy_chunks([1,2,3,4,5], 2)) == [[1,2],[3,4],[5]]
assert list(lazy_chunks([], 3)) == []
g = lazy_chunks(itertools.count(), 3)
assert next(g) == [0,1,2] and next(g) == [3,4,5]
pulled = []
def src():
    for i in range(10):
        pulled.append(i); yield i
g = lazy_chunks(src(), 4); next(g)
assert pulled == [0,1,2,3], pulled
try:
    lazy_chunks([1], 0)
except ValueError:
    pass
else:
    raise AssertionError('no ValueError at call')
"""),
}
code_results = {}
for name, (spec, tests) in TASKS.items():
    try:
        o = chat([{"role": "user", "content": spec + " Reply with one ```python code block containing only the module."}],
                 max_tokens=12000)
        text = msg(o).get("content") or ""
        m = re.findall(r"```(?:python)?\n(.*?)```", text, re.S)
        code = m[-1] if m else text
        with tempfile.TemporaryDirectory() as d:
            open(os.path.join(d, "solution.py"), "w").write(code)
            open(os.path.join(d, "t.py"), "w").write(tests)
            p = subprocess.run([sys.executable, "-I", "t.py"], cwd=d, capture_output=True, text=True, timeout=30,
                               env={"PYTHONPATH": d, "PATH": "/usr/bin:/bin"})
        # -I drops PYTHONPATH, so run the test with the folder on sys.path explicitly
        if p.returncode != 0 and "No module named 'solution'" in p.stderr:
            with tempfile.TemporaryDirectory() as d:
                open(os.path.join(d, "solution.py"), "w").write(code)
                open(os.path.join(d, "t.py"), "w").write("import sys; sys.path.insert(0, '.')\n" + tests)
                p = subprocess.run([sys.executable, "-I", "t.py"], cwd=d, capture_output=True, text=True, timeout=30)
        code_results[name] = {"ok": p.returncode == 0, "err": p.stderr.strip().splitlines()[-1:] , "secs": round(o["_wall"], 1),
                              "tokens": o["usage"]["completion_tokens"]}
    except Exception as e:
        code_results[name] = {"ok": False, "err": [f"error {e}"[:200]]}
results["coding"] = code_results
results["coding_score"] = f"{sum(r['ok'] for r in code_results.values())}/{len(code_results)}"

# ---- vision -------------------------------------------------------------------
if IMAGE:
    b64 = base64.b64encode(open(IMAGE, "rb").read()).decode()
    try:
        o = chat([{"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": "data:image/png;base64," + b64}},
            {"type": "text", "text": "This is a frame from a first-person horror game set in a warehouse. Describe what is "
                                     "in the frame, list any text you can read, and say whether anything looks broken "
                                     "(missing textures, clipping, z-fighting, wrong lighting)."}]}], max_tokens=4000)
        results["vision"] = {"answer": msg(o).get("content"), "secs": round(o["_wall"], 1)}
    except Exception as e:
        results["vision"] = {"answer": f"error {e}"}

json.dump(results, open(os.path.join(HERE, LABEL + ".json"), "w"), indent=2)
print(json.dumps({k: v for k, v in results.items() if k not in ("tools", "coding", "vision")}))
print("tools:", [(r["scenario"], r["ok"]) for r in tool_results])
print("coding:", {k: v["ok"] for k, v in code_results.items()})
