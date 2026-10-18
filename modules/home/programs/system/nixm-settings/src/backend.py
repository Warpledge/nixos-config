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


@dataclass
class State:
    """Everything the window shows, loaded in one go."""
    pages: list
    resolved: dict
    overrides: dict  # this machine's users.<user> block, as Python
    user_machines: list
    timezones: list

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
                s.description = descriptions.get(".".join(s.path), "")
    machine_doc = nixfile.to_python(nixfile.parse(read("machines", cfg.machine, "settings.nix")).root)
    try:
        zones = subprocess.run(["timedatectl", "list-timezones"], capture_output=True, text=True).stdout.split()
    except FileNotFoundError:
        zones = []
    return State(pages, data["resolved"], dig(machine_doc, ["users", cfg.user]) or {},
                 data["userMachines"], zones)


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
