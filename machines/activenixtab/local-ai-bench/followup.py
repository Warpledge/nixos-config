#!/usr/bin/env python3
"""Multi-turn coordinator check: answers read/shell/subagent calls with canned or
real read-only results and records the sequence until the model stops calling tools.
usage: followup.py BASE_URL MODEL LABEL"""
import json, os, re, subprocess, sys
READ_ONLY = {"cat", "head", "tail", "wc", "ls", "find", "grep", "rg", "journalctl", "dmesg", "git", "echo", "id",
             "systemctl", "iwctl", "nmcli", "stat", "file"}
sys.argv += [] ; BASE, MODEL, LABEL = sys.argv[1:4]
sys.argv = [sys.argv[0], BASE, MODEL, LABEL]
HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, "bench.py")).read()
# reuse chat(), TOOLS, SYSTEM, WRITE_RE without running the benchmark body
ns = {"__file__": os.path.join(HERE, "bench.py")}
exec(src.split("results = {")[0], ns)
exec("TOOLS = " + src.split("TOOLS = ")[1].split("def judge")[0], ns)
chat, TOOLS, SYSTEM, WRITE_RE = ns["chat"], ns["TOOLS"], ns["SYSTEM"], ns["WRITE_RE"]
REPO = "/home/kylerj/nixos-config"

def run_tool(name, args):
    if name == "read":
        p = args.get("path", "")
        p = p if p.startswith("/") else os.path.join(REPO, p)
        try:
            if os.path.isdir(p):
                return "\n".join(sorted(os.listdir(p)))
            return open(p).read()[:30000]
        except Exception as e:
            return f"error: {e}"
    if name == "shell":
        c = args.get("command", "")
        first = re.split(r"[\s|;&]+", c.strip())[0] if c.strip() else ""
        # Only read-only commands run for real; anything else is refused like opencode would
        if WRITE_RE.search(c) or "sudo" in c or first not in READ_ONLY:
            return "denied: not allowed for the coordinator"
        try:
            p = subprocess.run(["bash", "-c", c], cwd=REPO, capture_output=True, text=True, timeout=30)
        except subprocess.TimeoutExpired:
            return "timed out after 30 s"
        return ((p.stdout + p.stderr) or "(no output)")[:12000]
    if name == "subagent":
        return "Done. The worker made the change and checked it."
    return "denied"

SCEN = {
    "delegate_edit": "Add a Mod+V keybind that opens clipboard history to machines/activenixtab/home/binds.nix.",
    "parallel_split": "Two things: find out why the wifi drops (check the logs) and separately add `htop` to machines/activenixtab/home/apps.nix.",
}
out = {}
for name, prompt in SCEN.items():
    for trial in range(2):
        msgs = [{"role": "system", "content": SYSTEM}, {"role": "user", "content": prompt}]
        seq, wrote = [], False
        for turn in range(6):
            o = chat(msgs, max_tokens=6000, tools=TOOLS)
            m = o["choices"][0]["message"]
            calls = m.get("tool_calls") or []
            if not calls:
                break
            msgs.append({"role": "assistant", "content": m.get("content") or "", "tool_calls": calls})
            for c in calls:
                n, a = c["function"]["name"], json.loads(c["function"]["arguments"] or "{}")
                seq.append(n + (":" + a.get("command", "")[:60] if n == "shell" else "") + (":" + a.get("path", "") if n == "read" else ""))
                if n == "edit" or (n == "shell" and WRITE_RE.search(a.get("command", ""))):
                    wrote = True
                msgs.append({"role": "tool", "tool_call_id": c["id"], "content": run_tool(n, a)})
        delegated = sum(s.startswith("subagent") for s in seq)
        ok = not wrote and (delegated >= (1 if name == "delegate_edit" else 1)) and \
            (name != "parallel_split" or any(s.startswith(("shell:journalctl", "subagent")) for s in seq))
        out.setdefault(name, []).append({"ok": ok, "wrote": wrote, "seq": seq, "final": (m.get("content") or "")[:200]})
json.dump(out, open(LABEL + "-followup.json", "w"), indent=2)
for k, v in out.items():
    for r in v:
        print(k, r["ok"], r["seq"])
