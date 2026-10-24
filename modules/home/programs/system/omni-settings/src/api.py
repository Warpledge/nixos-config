"""Omni Settings' backend as JSON, for the QML front end. Each command loads only
what it needs and answers once: `omni-settings-backend <cmd> ['<json args>']`
prints {"ok": true, "data": ...} or {"ok": false, "error": ...}. Settings are
keyed "<domain>:<dotted.path>". Kept free of GTK, which the GTK app imports too."""

import difflib
import grp
import json
import os
import pwd
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import backend  # noqa: E402
import nixfile  # noqa: E402
import schema  # noqa: E402

#--- The root helper every rebuild goes through (nixos/system/user/omni-settings-helper.nix)
HELPER = "/run/current-system/sw/bin/omni-settings-apply"

#--- The master tabs across the top, each with its own page list
TABS = [("main", "Main"), ("packages", "Packages"), ("niri", "Niri"), ("ai", "AI"), ("docs", "Docs")]
TAB_ICONS = {"main": ("go-home-symbolic", "user-home-symbolic"),
             "packages": ("package-x-generic-symbolic", "system-software-install-symbolic"),
             "niri": ("view-grid-symbolic", "view-app-grid-symbolic"),
             "ai": ("applications-science-symbolic", "starred-symbolic"),
             "docs": ("accessories-dictionary-symbolic", "help-browser-symbolic")}

#--- Each tab's pages above its sections: key, title and icons to try.
#--- Shell shows only under niri, which also moves the Desktop section to Niri.
TOP = {"main": [("overview", "Overview", ("computer-symbolic",)),
                ("git", "Git", ("vcs-branch-symbolic", "branch-symbolic", "folder-remote-symbolic")),
                ("flatpaks", "Flatpaks", ("flatpak-symbolic", "system-software-install-symbolic")),
                ("backups", "Backups", ("drive-harddisk-symbolic", "document-save-symbolic")),
                ("people", "People", ("system-users-symbolic", "avatar-default-symbolic"))],
       "packages": [("packages", "Search", ("system-search-symbolic", "edit-find-symbolic"))],
       "niri": [("shell", "Shell", ("view-app-grid-symbolic",)),
                ("windowrules", "Window Rules",
                 ("window-new-symbolic", "preferences-system-windows-symbolic"))],
       "ai": [],
       "docs": []}

#--- Docs tab Gaming pages ahead of the game notes: [(key, title, icons)]
DOCS_GAMING = [("proton", "Launch Options", ("input-gaming-symbolic",)),
               ("protonversions", "Proton Versions",
                ("system-software-install-symbolic", "input-gaming-symbolic"))]

#--- Sections shown on a tab other than Main
SECTION_TAB = {"cloudai": "ai", "localai": "ai", "apps": "packages"}

USER_PACKAGES = ("user", ("userPackages",))

#--- App switches with a reset (appreset.py): user setting -> (app, its live file,
#--- the config's copy, pgrep -f pattern of a running app that rewrites the file
#--- on exit, extra warning). .db files are NeDB logs (one {"_id", "value"} per
#--- line), the rest JSON
APPS = {
    ("editors", "zed"): ("Zed", ".config/zed/settings.json",
                         ".config/zed/declarative-settings.json", None, ""),
    ("fileBrowsers", "duxFiles"): ("Dux Files", ".config/dfiles/ui-settings.json",
                                   ".local/state/dfiles-declared/ui-settings.json", None, ""),
    ("media", "freetube"): ("FreeTube", ".config/FreeTube/settings.db", ".config/FreeTube/hm_settings.db",
                            "freetube/resources/app.asar",
                            " Channels blocked in FreeTube but not yet synced to the config are "
                            "unblocked too."),
}

STATE_DIR = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"),
                         "omni-settings")
#--- What's New items the user dismissed, as "domain:dotted.path"
DISMISSED = os.path.join(STATE_DIR, "whats-new-dismissed.json")


#--------------------------------------------------------------------#
#-- Shared Helpers
#--------------------------------------------------------------------#
def new_id(domain, path):
    return f"{domain}:{'.'.join(path)}"


def parse_id(key):
    domain, _, dotted = key.partition(":")
    if domain not in ("machine", "user") or not dotted:
        raise ValueError(f"bad setting key: {key}")
    return domain, tuple(dotted.split("."))


def read_dismissed():
    try:
        with open(DISMISSED) as f:
            return set(json.load(f))
    except (OSError, ValueError):
        return set()


def shown(setting, value):
    if setting.kind == "bool":
        return "On" if value else "Off"
    if isinstance(value, dict):
        n = sum(len(v) for v in value.values())
        return f"{n} in {len(value)} categor{'y' if len(value) == 1 else 'ies'}" if n else "Not set"
    if value is None or value == "" or value == []:
        return "Not set"
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    return choice_label(setting, value) if setting.kind == "choice" else str(value)


def choice_label(setting, value):
    if str(value) in setting.labels:
        return setting.labels[str(value)]
    if value is None:
        return "None"
    if isinstance(value, int):
        return f"{value} px" if setting.path == ("cursorSize",) else str(value)
    return value[:1].upper() + value[1:]


def in_wheel():
    """From /etc/group, as the helper checks it, not the session's groups,
    which stay as they were at login."""
    try:
        me = pwd.getpwuid(os.getuid())
        return grp.getgrnam("wheel").gr_gid in os.getgrouplist(me.pw_name, me.pw_gid)
    except KeyError:
        return False


def helper():
    return os.path.realpath(HELPER) if os.path.exists(HELPER) else None


def access(cfg, state):
    """(admin, direct): admins write the files themselves when they can; for
    anyone else the root helper writes, and takes only their own app settings."""
    admin = bool(state.resolved["users"][cfg.user].get("admin")) and in_wheel()
    return admin, admin and backend.writable(cfg)


def changes_arg(args):
    """{(domain, path): value} from args' {"key": value} changes."""
    return {parse_id(k): v for k, v in (args.get("changes") or {}).items()}


def loaded(cfg):
    state = backend.load(cfg)
    if cfg.user not in state.resolved["users"]:
        raise backend.SettingsError(f"{cfg.user} isn't listed in machines/{cfg.machine}/settings.nix")
    return state


#--------------------------------------------------------------------#
#-- Commands
#--------------------------------------------------------------------#
def setting_json(cfg, state, s, multi, modules):
    value = state.value(cfg, s, cfg.machine)
    out = {"key": new_id(s.domain, s.path), "kind": s.kind, "title": s.title, "subtitle": s.subtitle,
           "note": s.note, "description": s.description, "icon": s.icon, "nullable": s.nullable,
           "value": value, "default": s.default, "shown": shown(s, value),
           "defaultShown": shown(s, s.default)}
    if s.kind == "choice":
        out["choices"] = [{"value": c, "label": choice_label(s, c)} for c in s.choices]
    if s.kind == "pick":
        out["data"] = s.data
    if s.kind == "list":
        out["options"] = s.options
        out["ports"] = s.ports
    if ".".join(s.path) in schema.SWITCH_LISTS:
        out["switchList"] = True
    if s.domain == "user" and multi:
        out["overridden"] = state.overridden(s)
        out["elsewhere"] = {m: state.value(cfg, s, m) for m in state.user_machines if m != cfg.machine}
    if s.domain == "user" and s.path in APPS:
        out["resettable"] = APPS[s.path][0]
    if s.path in modules:
        out["module"] = os.path.relpath(modules[s.path], cfg.flake)
    return out


def cmd_load(cfg, _args):
    """Everything the generated pages need, from one read of the settings."""
    state = loaded(cfg)
    admin, direct = access(cfg, state)
    wm = state.resolved.get("windowManager", "")
    multi = len(state.user_machines) > 1
    modules = backend.toggle_modules(cfg.flake)
    section_tab = dict(SECTION_TAB, **({"desktop": "niri"} if wm == "niri" else {}))

    nav = {tab: [] for tab, _ in TABS}
    for tab, _ in TABS:
        items = [{"id": key, "title": title, "icon": list(icons), "custom": True}
                 for key, title, icons in TOP[tab] if key != "shell" or wm == "niri"]
        if items:
            nav[tab].append({"id": "", "title": "", "items": items})
    pages, by_section = {}, {key: [] for key, _ in schema.SECTIONS}
    for page in state.pages:
        if page.section == "userpkgs":
            continue
        pid = "flatpaks" if page.section == "top" else f"page:{page.title}"
        groups = []
        for g in page.groups:
            locked = not direct and any(s.domain == "machine" for s in g.settings)
            groups.append({"title": g.title, "description": g.description, "locked": locked,
                           "settings": [setting_json(cfg, state, s, multi, modules) for s in g.settings],
                           "links": [{"tab": l.tab, "title": l.title, "subtitle": l.subtitle,
                                      "icon": l.icon} for l in g.links]})
        has_user = any(s.domain == "user" for g in page.groups for s in g.settings)
        pages[pid] = {"id": pid, "title": page.title, "description": page.description,
                      "icon": [page.icon, schema.FALLBACK_ICON], "intro": schema.PAGE_INTROS.get(page.title, ""),
                      "changeFor": multi and has_user, "groups": groups}
        if page.section != "top":
            by_section.get(page.section, by_section["apps"]).append(
                {"id": pid, "title": page.title, "icon": [page.icon, schema.FALLBACK_ICON]})
    for key, title in schema.SECTIONS:
        if by_section[key]:
            nav[section_tab.get(key, "main")].append({"id": key, "title": title, "items": by_section[key]})
    if any((s.domain, s.path) == USER_PACKAGES for p in state.pages for g in p.groups for s in g.settings):
        nav["packages"].append({"id": "userpkgs", "title": "User Packages",
                                "items": [{"id": "userpackages", "title": "All",
                                           "icon": ["package-x-generic-symbolic"], "custom": True}]})
    nav["docs"].append({"id": "gaming", "title": "Gaming",
                        "items": [{"id": k, "title": t, "icon": list(i), "custom": True}
                                  for k, t, i in DOCS_GAMING]})

    dismissed = read_dismissed()
    new = [{"key": new_id(d, p), "value": v} for d, p, v in state.new
           if (d == "user" or direct) and new_id(d, p) not in dismissed
           and any(s.domain == d and s.path == p for pg in state.pages for g in pg.groups for s in g.settings)]
    banner = ""
    if not helper():
        banner = "The Omni Settings helper isn't installed, so changes can't be applied"
    elif admin and not direct:
        banner = f"You can't edit the files in {cfg.flake}"
    return {"machine": cfg.machine, "user": cfg.user, "flake": cfg.flake, "wm": wm,
            "admin": admin, "direct": direct, "canApply": bool(helper()) and (direct or not admin),
            "banner": banner, "userMachines": state.user_machines,
            "tabs": [{"id": t, "title": title, "icon": list(TAB_ICONS[t])} for t, title in TABS],
            "nav": nav, "pages": pages, "whatsNew": new,
            "dmsSearch": [{"label": e.label, "description": e.description, "keywords": e.keywords,
                           "tab": e.link.tab, "page": e.link.page} for e in state.dms_entries]}


def cmd_list(_cfg, args):
    """A data list for kind "pick" settings (DATA_CHOICES): timezones, locales…"""
    if args.get("name") not in set(schema.DATA_CHOICES.values()):
        raise ValueError("unknown list")
    return [{"value": v, "label": label} for v, label in backend.data_list(args["name"])]


def cmd_review(cfg, args):
    """Each change as before -> after, and the lines it changes in each file.
    args: changes, machine (the Change For pick; null for all computers)."""
    state = loaded(cfg)
    settings = {(s.domain, s.path): s for p in state.pages for g in p.groups for s in g.settings}
    changes, machine = changes_arg(args), args.get("machine", cfg.machine)
    lines = []
    for key, value in changes.items():
        s = settings.get(key)
        if s is None:
            raise ValueError(f"unknown setting: {new_id(*key)}")
        lines.append({"key": new_id(*key), "title": s.title, "icon": s.icon,
                      "before": shown(s, state.value(cfg, s, machine or cfg.machine)),
                      "after": shown(s, value)})
    files = []
    try:
        edits = backend.render(cfg, changes, machine, state.user_machines)
    except (OSError, nixfile.NixError):
        edits = {}
    for path, (old, new) in edits.items():
        diff = list(difflib.unified_diff(old.splitlines(), new.splitlines(), lineterm="", n=1))[2:]
        files.append({"file": os.path.relpath(path, cfg.flake), "diff": diff,
                      "added": sum(1 for d in diff if d.startswith("+")),
                      "removed": sum(1 for d in diff if d.startswith("-"))})
    return {"changes": lines, "files": files}


def cmd_save(cfg, args):
    """Writes the changes without a rebuild, for an admin who can edit the files:
    another machine's block, which applies when that machine rebuilds. args as
    for review."""
    state = loaded(cfg)
    if not access(cfg, state)[1]:
        raise PermissionError("only an admin who can edit the files saves without a rebuild")
    backend.write(cfg, state, changes_arg(args), args.get("machine", cfg.machine), state.user_machines)
    return True


def cmd_dismiss(_cfg, args):
    """Hides What's New items (args.keys) until a later setting brings the page back."""
    keys = read_dismissed() | set(args.get("keys") or [])
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(DISMISSED, "w") as f:
        json.dump(sorted(keys), f)
    return sorted(keys)


def cmd_stale(cfg, _args):
    """Settings the templates dropped, which stop the files evaluating."""
    direct = in_wheel() and backend.writable(cfg)
    stale = backend.stale_settings(cfg, everyone=direct)
    return [{"where": w, "user": u, "key": ".".join(p), "mine": direct or w != "machine"}
            for w, u, p in stale]


def cmd_remove_stale(cfg, _args):
    """Removes them all for an admin who can write the files; anyone else asks
    the helper ({"clean": true}), which is a job."""
    if not (in_wheel() and backend.writable(cfg)):
        raise PermissionError("only an admin who can edit the files removes these directly")
    backend.remove_stale(cfg, backend.stale_settings(cfg, everyone=True))
    return True


COMMANDS = {"load": cmd_load, "list": cmd_list, "review": cmd_review, "save": cmd_save,
            "dismiss": cmd_dismiss,
            "stale": cmd_stale, "removeStale": cmd_remove_stale}


def run(cfg, cmd, args):
    """One command's reply as a dict."""
    fn = COMMANDS.get(cmd)
    if fn is None:
        return {"ok": False, "error": f"unknown command: {cmd}"}
    try:
        return {"ok": True, "data": fn(cfg, args if isinstance(args, dict) else {})}
    except backend.SettingsError as e:
        return {"ok": False, "error": str(e), "settings": True}
    except (OSError, ValueError, PermissionError, nixfile.NixError) as e:
        return {"ok": False, "error": str(e)}


def main():
    if len(sys.argv) < 2:
        sys.exit(f"usage: omni-settings-backend <{'|'.join(COMMANDS)}> ['<json args>']")
    try:
        args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    except ValueError:
        print(json.dumps({"ok": False, "error": "args aren't JSON"}))
        sys.exit(1)
    reply = run(backend.Config.from_env(), sys.argv[1], args)
    print(json.dumps(reply))
    sys.exit(0 if reply["ok"] else 1)


if __name__ == "__main__":
    main()
