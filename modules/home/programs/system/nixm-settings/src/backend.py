"""Reads the settings through lib/settings.nix, the same checks a rebuild
runs, and writes changes into the settings files."""

import json
import os
import re
import shutil
import subprocess
from dataclasses import dataclass

import nixfile
import schema

#--- Every machine through lib/settings.nix: the checks, this machine's
#--- final settings, and which machines list this user
EVAL = r"""
{libPath, machine, user}: let
  lib = import libPath;
  s = import ./lib/settings.nix {inherit lib;};
  dirs = lib.filterAttrs (n: t: t == "directory" && !lib.hasPrefix "_" n) (builtins.readDir ./machines);
  names = lib.attrNames dirs;
  lists = m: ((import (./machines + "/${m}/settings.nix")).users or {}) ? ${user};
in {
  checked = map (m: (s.forMachine m).machine.name) names;
  resolved = (s.forMachine machine).machine;
  choices = s.choices // s.userChoices;
  userMachines = lib.filter lists names;
}
"""


class SettingsError(Exception):
    pass


@dataclass
class Config:
    flake: str
    machine: str
    user: str
    lib: str

    @classmethod
    def from_env(cls):
        return cls(
            os.environ.get("NIXM_SETTINGS_FLAKE", "/etc/nixos-config"),
            os.environ["NIXM_SETTINGS_MACHINE"],
            os.environ.get("NIXM_SETTINGS_USER", os.environ.get("USER", "")),
            os.environ["NIXM_SETTINGS_LIB"],
        )

    def file(self, domain):
        if domain == "machine":
            return os.path.join(self.flake, "machines", self.machine, "settings.nix")
        return os.path.join(self.flake, "users", self.user, "settings.nix")


def error_message(stderr):
    """The text after the last `error:` line, without the trace above it."""
    lines, buf = stderr.splitlines(), []
    for line in lines:
        m = re.match(r"^\s*error:\s*(.*)", line)
        if m:
            buf = [m.group(1)] if m.group(1) else []
        elif line.strip():
            buf.append(line)
    return "\n".join(buf).strip() or stderr.strip()


def evaluate(cfg):
    cmd = ["nix-instantiate", "--eval", "--strict", "--json", "-E", EVAL,
           "--argstr", "libPath", cfg.lib, "--argstr", "machine", cfg.machine,
           "--argstr", "user", cfg.user]
    try:
        out = subprocess.run(cmd, cwd=cfg.flake, capture_output=True, text=True)
    except FileNotFoundError:
        raise SettingsError("nix-instantiate is not installed")
    if out.returncode != 0:
        raise SettingsError(error_message(out.stderr))
    return json.loads(out.stdout)


def dig(data, path):
    for k in path:
        if not isinstance(data, dict) or k not in data:
            return None
        data = data[k]
    return data


def lookup(tree, path):
    """(True, value) when `path` is set in `tree`, else (False, None)."""
    for key in path:
        if not isinstance(tree, dict) or key not in tree:
            return False, None
        tree = tree[key]
    return True, tree


def leaf_paths(tree, prefix=()):
    for key, value in tree.items():
        path = prefix + (key,)
        if isinstance(value, dict):
            yield from leaf_paths(value, path)
        else:
            yield path, value


def known(template, path):
    """Whether lib/settings.nix accepts `path`: a template key, or under a null one."""
    for key in path:
        if template is None:
            return True
        if not isinstance(template, dict) or key not in template:
            return False
        template = template[key]
    return True


def read_tree(path):
    with open(path) as f:
        return nixfile.to_python(nixfile.parse(f.read()).root)


def new_settings(cfg, overrides):
    """Template settings that this user's file and this machine's block both leave
    out, with the template's value: what was added since the file was made."""
    template = read_tree(os.path.join(cfg.flake, "users", "_template", "settings.nix"))
    own = read_tree(cfg.file("user"))
    return [(path, value) for path, value in leaf_paths(template)
            if path[0] not in schema.HIDDEN and not lookup(own, path)[0]
            and not lookup(overrides, path)[0]]


def stale_settings(cfg, everyone=False):
    """Settings the templates no longer have, as (where, user, path): "user" is that
    user's file, "override" their block in this machine's file, "machine" the
    machine's own settings. `everyone` adds the machine's other users (for admins)."""
    user_t = read_tree(os.path.join(cfg.flake, "users", "_template", "settings.nix"))
    machine_t = read_tree(os.path.join(cfg.flake, "machines", "_template", "settings.nix"))
    machine = read_tree(cfg.file("machine"))
    listed = list(machine.get("users") or {})
    users = [cfg.user] + ([u for u in listed if u != cfg.user] if everyone else [])
    out = []
    for user in users:
        path = os.path.join(cfg.flake, "users", user, "settings.nix")
        if os.path.exists(path):
            out += [("user", user, p) for p, _ in leaf_paths(read_tree(path)) if not known(user_t, p)]
        block = dig(machine, ["users", user]) or {}
        out += [("override", user, p) for p, _ in leaf_paths(block) if not known(user_t, p)]
    machine_own = {k: v for k, v in machine.items() if k != "users"}
    return out + [("machine", None, p) for p, _ in leaf_paths(machine_own) if not known(machine_t, p)]


def remove_stale(cfg, items):
    """Deletes the given stale settings from the files."""
    text = {}

    def edit(path, fn):
        if path not in text:
            with open(path) as f:
                text[path] = [f.read()] * 2  # [old, new]
        text[path][1] = fn(text[path][1])

    for where, user, path in items:
        path = list(path)
        if where == "user":
            edit(os.path.join(cfg.flake, "users", user, "settings.nix"),
                 lambda t, p=path: nixfile.remove_value(t, p))
        elif where == "override":
            edit(cfg.file("machine"),
                 lambda t, p=path, u=user: nixfile.remove_value(t, ["users", u] + p, keep=2))
        else:
            edit(cfg.file("machine"), lambda t, p=path: nixfile.remove_value(t, p))
    changed = [f for f, (old, new) in text.items() if old != new]
    for f in changed:
        save(f, text[f][1])
    if shutil.which("alejandra") and changed:
        subprocess.run(["alejandra", "-q"] + changed, capture_output=True)


@dataclass
class State:
    """Everything the window shows, loaded in one go."""
    pages: list
    resolved: dict
    overrides: dict  # this machine's users.<user> block, as Python
    user_machines: list
    timezones: list
    new: list  # (path, template value) for settings added since the user's file was made

    def value(self, cfg, setting):
        if setting.domain == "machine":
            return dig(self.resolved, setting.path)
        return dig(self.resolved["users"][cfg.user], setting.path)

    def overridden(self, setting):
        return setting.domain == "user" and dig(self.overrides, setting.path) is not None


def load(cfg):
    data = evaluate(cfg)
    read = lambda *p: open(os.path.join(cfg.flake, *p)).read()
    try:
        labels = schema.setup_labels(read("setup.sh"))
    except OSError:
        labels = {}
    pages = schema.build("machine", read("machines", "_template", "settings.nix"), data["choices"], labels)
    pages += schema.build("user", read("users", "_template", "settings.nix"), data["choices"], labels)
    pages = schema.arrange(pages)
    try:
        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), "descriptions.json")) as f:
            descriptions = json.load(f)
    except (OSError, ValueError):
        descriptions = {}
    for page in pages:
        for group in page.groups:
            for s in group.settings:
                entry = descriptions.get(".".join(s.path), "")
                if isinstance(entry, dict):
                    s.description, s.note = entry.get("text", ""), entry.get("note", "")
                else:
                    s.description = entry
    machine_doc = nixfile.to_python(nixfile.parse(read("machines", cfg.machine, "settings.nix")).root)
    try:
        zones = subprocess.run(["timedatectl", "list-timezones"], capture_output=True, text=True).stdout.split()
    except FileNotFoundError:
        zones = []
    overrides = dig(machine_doc, ["users", cfg.user]) or {}
    return State(pages, data["resolved"], overrides, data["userMachines"], zones,
                 new_settings(cfg, overrides))


def writable(cfg):
    return all(os.access(cfg.file(d), os.W_OK) for d in ("machine", "user"))


def write(cfg, state, changes, this_machine_only):
    """Writes `changes` ({(domain, path): value}) and checks the result.
    Returns the files' old text for undo; on a failed check the files are
    put back and SettingsError says why."""
    files = {d: cfg.file(d) for d in ("machine", "user")}
    old = {d: open(f).read() for d, f in files.items()}
    text = dict(old)
    for (domain, path), value in changes.items():
        path = list(path)
        if domain == "machine":
            text["machine"] = nixfile.set_value(text["machine"], path, value)
        elif this_machine_only:
            text["machine"] = nixfile.set_value(text["machine"], ["users", cfg.user] + path, value)
        else:
            text["user"] = nixfile.set_value(text["user"], path, value)
            # A change for every computer still loses to this one's override
            text["machine"] = nixfile.remove_value(text["machine"], ["users", cfg.user] + path, keep=2)

    changed = [d for d in files if text[d] != old[d]]
    for d in changed:
        save(files[d], text[d])
    if shutil.which("alejandra") and changed:
        subprocess.run(["alejandra", "-q"] + [files[d] for d in changed], capture_output=True)
    try:
        evaluate(cfg)
    except SettingsError:
        restore(cfg, old)
        raise
    return old


def save(path, text):
    # Rewrites in place, keeping the file's mode, owner and ACL
    with open(path, "r+") as f:
        f.seek(0)
        f.write(text)
        f.truncate()


def restore(cfg, old):
    for d, text in old.items():
        if open(cfg.file(d)).read() != text:
            save(cfg.file(d), text)
