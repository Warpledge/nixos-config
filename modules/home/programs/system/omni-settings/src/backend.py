"""Reads the settings through lib/settings.nix, the same checks a rebuild
runs, and writes changes into the settings files."""

import json
import os
import re
import shutil
import subprocess
from dataclasses import dataclass

import dms
import nixfile
import schema

#--- Every machine through lib/settings.nix: the checks, this machine's
#--- final settings, which machines list this user, and the user's final
#--- settings on each of them
EVAL = r"""
{libPath, machine, user}: let
  lib = import libPath;
  s = import ./lib/settings.nix {inherit lib;};
  dirs = lib.filterAttrs (n: t: t == "directory" && !lib.hasPrefix "_" n) (builtins.readDir ./machines);
  names = lib.attrNames dirs;
  lists = m: ((import (./machines + "/${m}/settings.nix")).users or {}) ? ${user};
  userMachines = lib.filter lists names;
in {
  checked = map (m: (s.forMachine m).machine.name) names;
  resolved = (s.forMachine machine).machine;
  choices = s.choices // s.userChoices;
  listChoices = s.listChoices;
  inherit userMachines;
  perMachine = lib.genAttrs userMachines (m: (s.forMachine m).machine.users.${user});
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
            os.environ.get("OMNI_SETTINGS_FLAKE", "/etc/nixos-config"),
            os.environ["OMNI_SETTINGS_MACHINE"],
            os.environ.get("OMNI_SETTINGS_USER", os.environ.get("USER", "")),
            os.environ["OMNI_SETTINGS_LIB"],
        )

    def file(self, domain, machine=None):
        if domain == "machine":
            return os.path.join(self.flake, "machines", machine or self.machine, "settings.nix")
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
        if isinstance(value, dict) and path not in schema.GROUPED:
            yield from leaf_paths(value, path)
        else:
            yield path, value


def known(template, path):
    """Whether lib/settings.nix accepts `path`: a template key, or under a null one."""
    for i, key in enumerate(path):
        if template is None or tuple(path[:i]) in schema.GROUPED:
            return True
        if not isinstance(template, dict) or key not in template:
            return False
        template = template[key]
    return True


#--- A router line `lib.optionals user.<toggle> [./file]`, or one whose condition
#--- is toggles joined by ||; `(import ./dir user)` too
ROUTE = re.compile(r"lib\.optionals?\s+(\([^()]*\)|(?:user|anyUser)\.[\w.]+)\s+\[\s*\(?(?:import\s+)?(\./[\w./-]+)")
EITHER = re.compile(r"\(\s*(?:(?:user|anyUser)\.[\w.]+\s*\|\|\s*)+(?:user|anyUser)\.[\w.]+\s*\)")
TOGGLE = re.compile(r"(user|anyUser)\.([\w.]+)")


def toggle_modules(flake):
    """{setting path: the .nix file its toggle imports}, read from the routers
    under modules/. A toggle's own line wins over a shared || one, and a home
    module over a system one; a folder gives its default.nix."""
    found = {}  # path -> (rank, file); lower rank wins
    for root, _, files in os.walk(os.path.join(flake, "modules")):
        for name in files:
            if not name.endswith(".nix"):
                continue
            try:
                with open(os.path.join(root, name)) as f:
                    text = f.read()
            except OSError:
                continue
            for cond, target in ROUTE.findall(text):
                shared = cond.startswith("(")
                if shared and not EITHER.fullmatch(cond):
                    continue
                path = os.path.normpath(os.path.join(root, target))
                if os.path.isdir(path):
                    path = os.path.join(path, "default.nix")
                if not os.path.isfile(path):
                    continue
                for who, dotted in TOGGLE.findall(cond):
                    key, rank = tuple(dotted.split(".")), (who != "user") * 2 + shared
                    if key not in found or rank < found[key][0]:
                        found[key] = (rank, path)
    return {key: path for key, (_, path) in found.items()}


def read_tree(path):
    with open(path) as f:
        return nixfile.to_python(nixfile.parse(f.read()).root)


def new_settings(cfg, overrides):
    """Template settings that this user's file and this machine's block both leave
    out, with the template's value: what was added since the file was made. Then
    the same for the machine's own file, as (domain, path, value)."""
    template = read_tree(os.path.join(cfg.flake, "users", "_template", "settings.nix"))
    own = read_tree(cfg.file("user"))
    out = [("user", path, value) for path, value in leaf_paths(template)
           if path[0] not in schema.HIDDEN and not lookup(own, path)[0]
           and not lookup(overrides, path)[0]]
    machine_t = read_tree(os.path.join(cfg.flake, "machines", "_template", "settings.nix"))
    machine = read_tree(cfg.file("machine"))
    # A null template value (hostName) is meant to be left out
    return out + [("machine", path, value) for path, value in leaf_paths(machine_t)
                  if path[0] not in schema.HIDDEN and value is not None
                  and not lookup(machine, path)[0]]


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
    per_machine: dict  # machine -> this user's final settings there
    lists: dict  # DATA_CHOICES name -> [(value, label)]
    new: list  # (domain, path, template value) for settings added since a file was made
    dms_entries: list  # dms.Entry, for search

    def value(self, cfg, setting, machine=None):
        """The setting's value on this machine, or for a user setting on `machine`."""
        if setting.domain == "machine":
            return dig(self.resolved, setting.path)
        if machine and machine in self.per_machine:
            return dig(self.per_machine[machine], setting.path)
        return dig(self.resolved["users"][cfg.user], setting.path)

    def overridden(self, setting):
        return setting.domain == "user" and dig(self.overrides, setting.path) is not None


HERE = os.path.dirname(os.path.realpath(__file__))


def describe(setting, entry):
    """Applies a descriptions.json entry: a string is the long text; an object
    may set title, summary (the line under the name), note (a caution), text,
    icon (names or .desktop ids to try) and choices (value -> label)."""
    if isinstance(entry, str):
        setting.description = entry
        return
    if not isinstance(entry, dict):
        return
    setting.title = entry.get("title", setting.title)
    setting.subtitle = entry.get("summary", setting.subtitle)
    setting.note = entry.get("note", "")
    setting.description = entry.get("text", "")
    icon = entry.get("icon", [])
    setting.icon = [icon] if isinstance(icon, str) else list(icon)
    setting.labels = {str(k): v for k, v in (entry.get("choices") or {}).items()}


#--- claude.skillModels/agentModels -> the file whose frontmatter model null keeps
OWN_MODEL_FILES = {"skillModels": "modules/home/programs/ai/skills/{}/SKILL.md",
                   "agentModels": "modules/home/programs/ai/agents/{}.md"}


def name_own_models(flake, pages):
    """Labels each Claude skill's and subagent's null model with the model its
    file sets, or the session's when it sets none."""
    for s in schema.flat(pages):
        if len(s.path) != 3 or s.path[0] != "claude" or s.path[1] not in OWN_MODEL_FILES:
            continue
        name = re.sub(r"[A-Z]", lambda m: "-" + m.group(0).lower(), s.path[2])
        model = None
        try:
            with open(os.path.join(flake, OWN_MODEL_FILES[s.path[1]].format(name))) as f:
                head = f.read().split("\n---", 1)[0]
            m = re.search(r"^model:\s*(\S+)", head, re.M)
            model = m and m.group(1)
        except OSError:
            pass
        own = f"{model[:1].upper()}{model[1:]}" if model and model != "inherit" else "The session's model"
        s.labels = {**s.labels, "None": f"{own} (its own)"}


def data_list(name):
    """One of the lists default.nix builds, as [(value, label)]: a line is a
    value, then optionally whitespace and a label."""
    if name == "timezones":
        try:
            out = subprocess.run(["timedatectl", "list-timezones"], capture_output=True, text=True)
            return [(z, z.replace("_", " ")) for z in out.stdout.split()]
        except OSError:
            return []
    try:
        with open(os.path.join(HERE, f"{name}.txt")) as f:
            rows = [line.strip().split(None, 1) for line in f if line.strip()]
    except OSError:
        return []
    return [(r[0], f"{r[0]} — {r[1]}" if len(r) > 1 else r[0]) for r in rows]


def has_battery():
    try:
        return any(n.startswith("BAT") for n in os.listdir("/sys/class/power_supply"))
    except OSError:
        return False


def load(cfg):
    data = evaluate(cfg)

    def read(*p):
        with open(os.path.join(cfg.flake, *p)) as f:
            return f.read()
    try:
        labels = schema.setup_labels(read("setup.sh"))
    except OSError:
        labels = {}
    list_choices = data.get("listChoices") or {}
    pages = schema.build("machine", read("machines", "_template", "settings.nix"), data["choices"],
                         labels, list_choices)
    pages += schema.build("user", read("users", "_template", "settings.nix"), data["choices"],
                          labels, list_choices)
    machine = data["resolved"]
    wm = machine.get("windowManager", "")
    links = dms.links(wm, bool(dig(machine, ["printing", "enable"])), has_battery()) \
        if dms.binary() else []
    pages = schema.arrange(pages, links)
    try:
        with open(os.path.join(HERE, "descriptions.json")) as f:
            descriptions = json.load(f)
    except (OSError, ValueError):
        descriptions = {}
    for page in pages:
        for group in page.groups:
            for s in group.settings:
                # "a.b.*" describes every a.b.<name>, under its own entry's keys
                entry = descriptions.get(".".join(s.path), "")
                shared = descriptions.get(".".join(s.path[:-1] + ("*",)))
                if isinstance(shared, dict) and isinstance(entry, dict):
                    entry = {**shared, **entry}
                elif not entry and shared:
                    entry = shared
                describe(s, entry)
    pages = schema.pair_up(pages)
    name_own_models(cfg.flake, pages)
    machine_doc = nixfile.to_python(nixfile.parse(read("machines", cfg.machine, "settings.nix")).root)
    lists = {name: data_list(name) for name in set(schema.DATA_CHOICES.values())}
    overrides = dig(machine_doc, ["users", cfg.user]) or {}
    return State(pages, machine, overrides, data["userMachines"], data.get("perMachine") or {}, lists,
                 new_settings(cfg, overrides), dms.search_index(links, wm))


def writable(cfg):
    return all(os.access(cfg.file(d), os.W_OK) for d in ("machine", "user"))


def write(cfg, state, changes, machine, everywhere=()):
    """Writes `changes` ({(domain, path): value}) and checks the result. User
    settings go in `machine`'s block for this user, or with `machine` None in the
    user's own file, cleared from the blocks of every machine in `everywhere`.
    Returns the files' old text for undo; on a failed check the files are put
    back and SettingsError says why."""
    edits = render(cfg, changes, machine, everywhere)
    old = {f: before for f, (before, _) in edits.items()}
    for f, (_, after) in edits.items():
        save(f, after)
    changed = list(edits)
    if shutil.which("alejandra") and changed:
        subprocess.run(["alejandra", "-q"] + changed, capture_output=True)
    try:
        evaluate(cfg)
    except SettingsError:
        restore(cfg, old)
        raise
    return old


def render(cfg, changes, machine, everywhere=()):
    """What write() would put in each file, unformatted: {path: (old, new)} for
    the files it changes."""
    old, text = {}, {}

    def edit(path, fn):
        if path not in text:
            old[path] = text[path] = slurp(path)
        text[path] = fn(text[path])

    block = ["users", cfg.user]
    for (domain, path), value in changes.items():
        path = list(path)
        if domain == "machine":
            edit(cfg.file("machine"), lambda t: nixfile.set_value(t, path, value))
        elif machine:
            edit(cfg.file("machine", machine), lambda t: nixfile.set_value(t, block + path, value))
        else:
            edit(cfg.file("user"), lambda t: nixfile.set_value(t, path, value))
            # A change for every computer still loses to a computer's own block
            for m in set(everywhere) | {cfg.machine}:
                edit(cfg.file("machine", m), lambda t: nixfile.remove_value(t, block + path, keep=2))
    return {f: (old[f], text[f]) for f in text if text[f] != old[f]}


def settings_file(path):
    """Whether `path` is a machine's or user's settings.nix, the only repo
    files the app edits; modules/ and the templates are never written."""
    real = os.path.realpath(path)
    folder = os.path.dirname(real)
    return (os.path.basename(real) == "settings.nix"
            and os.path.basename(os.path.dirname(folder)) in ("machines", "users")
            and os.path.basename(folder) != "_template")


def save(path, text):
    if not settings_file(path):
        raise PermissionError(f"Omni Settings only writes machines/ and users/ settings files, not {path}")
    # Rewrites in place, keeping the file's mode, owner and ACL
    with open(path, "r+") as f:
        f.seek(0)
        f.write(text)
        f.truncate()


def slurp(path):
    with open(path) as f:
        return f.read()


def restore(cfg, old):
    """Puts back the files write() returned, keyed by path."""
    for path, text in old.items():
        if slurp(path) != text:
            save(path, text)
