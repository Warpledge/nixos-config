"""nixm-settings-apply: run as root by pkexec after the caller types their own
password. Applies the caller's own app settings and rebuilds; it never touches
machine settings or another user's, and accepts only template keys and kinds.

Usage: nixm-settings-apply '{"mode": "switch"|"boot", "thisMachineOnly": bool,
                              "changes": [[["media", "mpv"], true], ...]}'"""

import fcntl
import json
import os
import pwd
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import backend  # noqa: E402
import nixfile  # noqa: E402
import schema  # noqa: E402

LOCK = "/run/nixm-settings-apply.lock"


def refuse(message):
    print(f"error: {message}", flush=True)
    sys.exit(2)


def lookup(tree, path):
    """(True, value) when `path` is a setting in `tree`, else (False, None)."""
    for key in path:
        if not isinstance(tree, dict) or key not in tree:
            return False, None
        tree = tree[key]
    return True, tree


def same_kind(template, value):
    if isinstance(template, bool):
        return isinstance(value, bool)
    if isinstance(template, list):
        return isinstance(value, list) and all(isinstance(v, str) for v in value)
    if template is None or isinstance(template, str):
        return value is None or isinstance(value, str)
    return False


def main():
    uid = os.environ.get("PKEXEC_UID")
    if os.geteuid() != 0 or uid is None:
        refuse("run this through pkexec")
    caller = pwd.getpwuid(int(uid)).pw_name

    try:
        request = json.loads(sys.argv[1])
        mode = request["mode"]
        this_only = bool(request.get("thisMachineOnly"))
        raw = request["changes"]
    except (IndexError, ValueError, KeyError, TypeError):
        refuse("bad request")
    if mode not in ("switch", "boot") or not isinstance(raw, list) or not raw:
        refuse("bad request")

    cfg = backend.Config(os.environ["NIXM_SETTINGS_FLAKE"], os.environ["NIXM_SETTINGS_MACHINE"],
                         caller, os.environ["NIXM_SETTINGS_LIB"])
    with open(os.path.join(cfg.flake, "users", "_template", "settings.nix")) as f:
        template = nixfile.to_python(nixfile.parse(f.read()).root)

    changes = {}
    for item in raw:
        if not (isinstance(item, list) and len(item) == 2 and isinstance(item[0], list)
                and item[0] and all(isinstance(k, str) for k in item[0])):
            refuse("bad request")
        path, value = item
        found, default = lookup(template, path)
        if not found or path[0] in schema.HIDDEN or isinstance(default, dict):
            refuse(f"`{'.'.join(path)}` can't be changed here")
        if not same_kind(default, value):
            refuse(f"`{'.'.join(path)}` got the wrong kind of value")
        changes[("user", tuple(path))] = value

    with open(LOCK, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            state = backend.evaluate(cfg)
        except backend.SettingsError as e:
            refuse(f"the settings files don't evaluate right now:\n{e}")
        if caller not in state["resolved"]["users"]:
            refuse(f"{caller} isn't listed in machines/{cfg.machine}/settings.nix")

        print("Saving your settings…", flush=True)
        try:
            old = backend.write(cfg, None, changes, this_only)
        except backend.SettingsError as e:
            refuse(f"these settings don't work, nothing was saved:\n{e}")

        print("Building the system…", flush=True)
        env = {"PATH": os.environ["PATH"], "HOME": "/root", "LANG": "C.UTF-8"}
        target = f"{cfg.flake}#{cfg.machine}"
        result = subprocess.run(["nixos-rebuild", mode, "--flake", target], env=env)
        if result.returncode != 0:
            backend.restore(cfg, old)
            print("error: the rebuild failed, so your settings were put back", flush=True)
            sys.exit(1)


if __name__ == "__main__":
    main()
