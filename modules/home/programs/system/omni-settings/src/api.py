"""Omni Settings' backend as JSON, for the QML front end. Each command loads only
what it needs and answers once: `omni-settings-backend <cmd> ['<json args>']`
prints {"ok": true, "data": ...} or {"ok": false, "error": ...}. Settings are
keyed "<domain>:<dotted.path>". The job service imports it too."""

import dataclasses
import difflib
import grp
import json
import os
import pwd
import selectors
import shutil
import socket
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import backend  # noqa: E402
import backupstate  # noqa: E402
import bootstate  # noqa: E402
import closure  # noqa: E402
import dms  # noqa: E402
import docstate  # noqa: E402
import flatpakstate  # noqa: E402
import gitstate  # noqa: E402
import keybindstate  # noqa: E402
import nixfile  # noqa: E402
import packagestate  # noqa: E402
import peoplestate  # noqa: E402
import resetstate  # noqa: E402
import protonstate  # noqa: E402
import schema  # noqa: E402
import servicestate  # noqa: E402
import system  # noqa: E402
import windowrulestate as wr  # noqa: E402

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
                ("people", "Users", ("system-users-symbolic", "avatar-default-symbolic"))],
       "packages": [("packages", "Search", ("system-search-symbolic", "edit-find-symbolic"))],
       "niri": [("shell", "Shell", ("view-app-grid-symbolic",)),
                ("windowrules", "Window Rules",
                 ("window-new-symbolic", "preferences-system-windows-symbolic")),
                ("keybinds", "Keybinds", ("input-keyboard-symbolic", "preferences-desktop-keyboard-symbolic"))],
       "ai": [],
       "docs": []}

#--- Docs tab Gaming pages ahead of the game notes: [(key, title, icons)]
DOCS_GAMING = [("proton", "Launch Options", ("input-gaming-symbolic",)),
               ("protonversions", "Proton Versions",
                ("system-software-install-symbolic", "input-gaming-symbolic"))]

#--- The line under each page in the page list that has no description of its own
NAV_SUBTITLES = {"overview": "Updates, rebuild, versions", "git": "Changes, commits, pull requests",
                 "flatpaks": "Apps, updates, repair", "backups": "Back up app data",
                 "people": "Who can log in", "packages": "Find packages in nixpkgs",
                 "shell": "DankMaterialShell's settings", "windowrules": "Rules for each app's windows",
                 "keybinds": "Change, add and turn off shortcuts",
                 "userpackages": "Packages you added from Search",
                 "proton": "Launch options to copy", "protonversions": "Proton builds installed"}

#--- DMS tabs shown as buttons on the Overview (Shell page under niri), in this order
QUICK = ["display_config", "keybinds", "mouse_touchpad", "theme", "wallpaper", "dankbar_settings",
         "notifications", "network_wifi", "audio"]
HISTORY = 8  # versions the Overview lists

#--- Sections shown on a tab other than Main
SECTION_TAB = {"cloudai": "ai", "localai": "ai", "apps": "packages"}

USER_PACKAGES = ("user", ("userPackages",))
KEYBINDS = ("user", schema.KEYBINDS)

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
    if setting.kind == "keybinds":
        return f"{len(value)} keybind{'' if len(value) == 1 else 's'} changed" if value else "Not set"
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
    reset = s.domain == "user" and resetstate.available(s.path)
    if reset:
        out["resettable"] = {"app": reset[0], "file": os.path.basename(reset[1]), "extra": reset[4]}
    if s.path in modules:
        out["module"] = os.path.relpath(modules[s.path], cfg.flake)
    return out


def shell_categories(shell):
    """The Shell page's categories, each and its links in dms.LINKS order."""
    rank = {link.tab: i for i, link in enumerate(dms.LINKS)}
    cats = [{"title": t, "links": sorted(ls, key=lambda j: rank.get(j["tab"], len(rank)))}
            for t, ls in shell.items()]
    return sorted(cats, key=lambda c: rank.get(c["links"][0]["tab"], len(rank)))


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
        items = [{"id": key, "title": title, "icon": list(icons), "custom": True,
                  "subtitle": NAV_SUBTITLES.get(key, "")}
                 for key, title, icons in TOP[tab] if key != "shell" or wm == "niri"]
        if items:
            nav[tab].append({"id": "", "title": "", "items": items})
    pages, by_section = {}, {key: [] for key, _ in schema.SECTIONS}
    # Under niri every DMS link moves to the Shell page, in categories (shellLinks)
    shell_links = wm == "niri"
    shell = {}
    for page in state.pages:
        if page.section in ("userpkgs", "keybinds"):
            continue
        pid = schema.TOP_PAGES[page.title] if page.section == "top" else f"page:{page.title}"
        groups = []
        for g in page.groups:
            links = [{"tab": l.tab, "title": l.title, "subtitle": l.subtitle, "icon": l.icon} for l in g.links]
            if shell_links:
                for l, j in zip(g.links, links):
                    shell.setdefault(l.group or l.page, []).append(j)
                if not g.settings:
                    continue
                links = []
            locked = not direct and any(s.domain == "machine" for s in g.settings)
            groups.append({"title": g.title, "description": g.description, "locked": locked,
                           "settings": [setting_json(cfg, state, s, multi, modules) for s in g.settings],
                           "links": links})
        if not groups:
            continue
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
    user_packages = next((s for p in state.pages for g in p.groups for s in g.settings
                          if (s.domain, s.path) == USER_PACKAGES), None)
    if user_packages:
        nav["packages"].append({"id": "userpkgs", "title": "User Packages",
                                "items": [{"id": "userpackages", "title": "All",
                                           "subtitle": NAV_SUBTITLES["userpackages"],
                                           "icon": ["package-x-generic-symbolic"], "custom": True}]})
    keybinds = next((s for p in state.pages for g in p.groups for s in g.settings
                     if (s.domain, s.path) == KEYBINDS), None)
    guides = [{"id": d.key, "title": d.title, "icon": ["help-browser-symbolic"], "custom": True}
              for d in docstate.guide_docs(cfg.flake)]
    if guides:
        nav["docs"].append({"id": "guides", "title": "Guides", "items": guides})
    nav["docs"].append({"id": "gaming", "title": "Gaming",
                        "items": [{"id": k, "title": t, "icon": list(i), "custom": True,
                                   "subtitle": NAV_SUBTITLES.get(k, "")}
                                  for k, t, i in DOCS_GAMING]
                        + [{"id": d.key, "title": d.title, "icon": ["input-gaming-symbolic"], "custom": True}
                           for d in docstate.game_docs(cfg.flake)]})

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
            "nav": nav, "pages": pages, "whatsNew": new, "quick": QUICK,
            "shellLinks": shell_categories(shell),
            "userPackages": user_packages and setting_json(cfg, state, user_packages, multi, modules),
            "keybinds": keybinds and setting_json(cfg, state, keybinds, multi, modules),
            "starter": packagestate.STARTER,
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
    return {"machine": cfg.machine, "direct": direct, "helper": bool(helper()),
            "items": [{"where": w, "user": u, "key": ".".join(p), "mine": direct or w != "machine"}
                      for w, u, p in stale]}


def cmd_remove_stale(cfg, _args):
    """Removes them all for an admin who can write the files; anyone else asks
    the helper ({"clean": true}), which is a job."""
    if not (in_wheel() and backend.writable(cfg)):
        raise PermissionError("only an admin who can edit the files removes these directly")
    backend.remove_stale(cfg, backend.stale_settings(cfg, everyone=True))
    return True


#--------------------------------------------------------------------#
#-- Overview
#--------------------------------------------------------------------#
def cmd_overview(cfg, _args):
    """What this computer runs, the versions it can switch to, the clean-up's
    plan and the last failed run."""
    import jobs  # jobs.py imports this module
    i = system.info(cfg.flake)
    running, booted, default = (os.path.realpath(p) for p in
                                (closure.CURRENT, closure.BOOTED, closure.SYSTEM_PROFILE))
    policy = system.clean_policy()
    doomed = sorted(g.number for g in system.to_delete(i.generations, policy))
    failed = jobs.last_failed()
    free, total = i.disk
    return {"hostname": i.hostname, "pretty": i.pretty, "kernel": i.kernel, "generation": i.generation,
            "pending": i.pending, "newKernel": i.new_kernel, "updated": i.updated,
            "diskFree": free, "diskTotal": total,
            "generations": [{"number": g.number, "when": g.when, "version": g.version, "kernel": g.kernel,
                             "path": g.path, "running": g.path == running, "booted": g.path == booted,
                             "next": g.path == default} for g in i.generations[:HISTORY]],
            "cleanUp": {"total": len(i.generations), "doomed": doomed, "keep": policy.keep,
                        "since": policy.since_text, "schedule": policy.schedule},
            "lastFailed": dict(zip(("title", "when", "heading", "reason"), failed[:4])) if failed else None}


def cmd_freed(_cfg, _args):
    """Bytes only the generations a clean-up deletes use; slow, so asked for apart."""
    gens = closure.generations()
    doomed = system.to_delete(gens, system.clean_policy())
    return system.freed_estimate(doomed, [g for g in gens if g not in doomed]) if doomed else 0


def cmd_boot(_cfg, _args):
    """The last startup's stages, its slowest units and the chain it waited on; slow,
    so asked for apart."""
    return bootstate.summary()


def cmd_check_updates(cfg, _args):
    """The newest version of each flake input, locked into a separate file the
    update job takes as args.lock; flake.lock stays as it is."""
    lock, changes = system.check_updates(cfg.flake)
    return {"lock": lock, "changes": [{"name": c.name, "old": c.old, "new": c.new, "link": c.link}
                                      for c in changes]}


def cmd_compare(_cfg, args):
    """What switching from the running system to generation args.number changes."""
    gen = next((g for g in closure.generations() if g.number == args.get("number")), None)
    if gen is None:
        raise ValueError("no such version")
    return closure.diff(closure.CURRENT, gen.path).as_json()


def cmd_failed_log(_cfg, _args):
    import jobs
    failed = jobs.last_failed()
    return dict(zip(("title", "when", "heading", "reason", "log", "errors"), failed)) if failed else None


def cmd_forget_failed(_cfg, _args):
    import jobs
    for path in (jobs.FAILED_LOG, jobs.FAILED_ERRORS):
        try:
            os.remove(path)
        except FileNotFoundError:
            pass
    return True


#--------------------------------------------------------------------#
#-- Git
#--------------------------------------------------------------------#
def commit_json(c):
    short, full, subject, author, stamp = c
    return {"short": short, "hash": full, "subject": subject, "author": author, "when": int(stamp)}


def cmd_git(cfg, args):
    """Where the config repo stands; args.force for Refresh (gitstate.remote
    limits how often it fetches and calls GitHub), args.cached to skip any fetch."""
    repo = gitstate.github_repo(cfg.flake)
    fetch_err, prs, pr_err, limited = gitstate.remote(cfg.flake, repo, bool(args.get("force")),
                                                      bool(args.get("cached")))
    try:
        status, upstream, changed, outgoing, incoming, recent, fetched = gitstate.snapshot(cfg.flake)
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        raise ValueError(f"Couldn't read the repo: {e}")
    files = [{"path": line[3:], "state": gitstate.STATES.get(line[:2].strip()[:1], line[:2].strip())}
             for line in changed[:gitstate.MAX_FILES]]
    return {"repo": repo, "branch": status.branch, "upstream": upstream, "fetched": fetched,
            "fetchErr": fetch_err, "changed": files, "moreChanged": max(0, len(changed) - gitstate.MAX_FILES),
            "outgoing": [commit_json(c) for c in outgoing], "incoming": [commit_json(c) for c in incoming],
            "recent": [commit_json(c) for c in recent],
            "prs": None if prs is None else [
                {"number": p.get("number"), "title": p.get("title", ""), "url": p.get("html_url", ""),
                 "author": (p.get("user") or {}).get("login", "?"), "branch": (p.get("head") or {}).get("label", ""),
                 "updated": gitstate.iso_epoch(p.get("updated_at")), "draft": bool(p.get("draft"))}
                for p in prs],
            "prErr": pr_err, "limited": limited, "backup": gitstate.backup_url(cfg.flake)}


def cmd_set_backup(cfg, args):
    """Sets (or with an empty url, clears) the repo this clone backs up to."""
    if access(cfg, loaded(cfg)) != (True, True):
        raise ValueError("Only an admin can set where the config backs up to")
    try:
        return gitstate.set_backup(cfg.flake, cfg.machine, [f"machines/{cfg.machine}", f"users/{cfg.user}"],
                                   (args.get("url") or "").strip())
    except gitstate.PullError as e:
        raise ValueError(str(e))


def cmd_git_summary(cfg, _args):
    """The counts the page list shows beside Git."""
    try:
        return gitstate.summary(cfg.flake)
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        raise ValueError(str(e))


#--------------------------------------------------------------------#
#-- Flatpaks
#--------------------------------------------------------------------#
def ref_json(lst, ref):
    return dict(dataclasses.asdict(ref), key=ref.key, bundle=lst.bundle(ref))


def cmd_flatpaks(_cfg, _args):
    """The apps and runtimes installed and the apps switched off here."""
    if flatpakstate.binary() is None:
        return {"installed": False}
    lst = flatpakstate.listing()
    have = {r.ref for r in lst.runtimes}
    return {"installed": True, "flatseal": any(a.id == flatpakstate.FLATSEAL for a in lst.apps),
            "apps": [dict(ref_json(lst, a), missing=bool(a.runtime and a.runtime not in have)) for a in lst.apps],
            "off": [ref_json(lst, a) for a in lst.off],
            "runtimes": [ref_json(lst, r) for r in lst.runtimes],
            "runtimeBytes": sum(flatpakstate.size_bytes(r.size) for r in lst.runtimes)}


def cmd_flatpak_updates(_cfg, _args):
    """The names of the apps and runtimes with a newer version."""
    try:
        return flatpakstate.updates(flatpakstate.listing().installations())
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        raise ValueError(str(e))


def run_streamed(commands):
    """Runs `commands` in turn, each output line to stderr for the front end's
    progress; stops at the first that fails. Returns (ok, last lines)."""
    tail = []
    for command in commands:
        proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                stdin=subprocess.DEVNULL)
        buffer = b""
        while chunk := proc.stdout.read1(65536):
            *lines, buffer = (buffer + chunk).replace(b"\r", b"\n").split(b"\n")
            for raw in lines:
                line = flatpakstate.clean(raw.decode(errors="replace"))
                if line:
                    tail = (tail + [line])[-20:]
                    print(line, file=sys.stderr, flush=True)
        if proc.wait() != 0:
            return False, tail
    return True, tail


def cmd_flatpak_run(_cfg, args):
    """One Flatpak action, its progress on stderr: uninstall, install (an app
    switched off here), runtime (an app's missing runtime), update, unused or
    repair. args.key names the app as "<installation>:<id>"."""
    lst, action = flatpakstate.listing(), args.get("action")
    apps = {a.key: a for a in lst.apps}
    off = {a.key: a for a in lst.off}
    ref = apps.get(args.get("key")) or off.get(args.get("key"))
    if action in ("uninstall", "runtime") and args.get("key") not in apps:
        raise ValueError("that app isn't installed")
    if action == "install" and args.get("key") not in off:
        raise ValueError("that app isn't switched off here")
    if action == "uninstall":
        commands, failed = flatpakstate.uninstall(ref), f"Couldn't uninstall {ref.name}"
    elif action == "install":
        if lst.bundle(ref):
            raise ValueError(f"Install {ref.name} again from the file it came from")
        commands, failed = flatpakstate.reinstall(ref), f"Couldn't install {ref.name}"
    elif action == "runtime":
        remote = flatpakstate.runtime_source(lst, ref)
        if remote is None:
            raise ValueError(f"No source to install {ref.runtime} from")
        commands, failed = flatpakstate.install_runtime(ref, remote), "Couldn't install the runtime"
    elif action == "update":
        commands, failed = flatpakstate.update_all(lst), "Couldn't update"
    elif action == "unused":
        commands, failed = flatpakstate.remove_unused(lst), "Couldn't remove the unused runtimes"
    elif action == "repair":
        commands, failed = flatpakstate.repair(lst), "Couldn't finish the repair"
    else:
        raise ValueError(f"unknown action: {action}")
    ok, tail = run_streamed(commands)
    if not ok:
        raise ValueError(f"{failed}\n\n" + ("\n".join(tail[-6:]) or "Flatpak didn't say why."))
    if action == "uninstall":
        if not lst.bundle(ref):
            flatpakstate.mark_off(ref)
        return f"{ref.name} uninstalled"
    if action == "install":
        flatpakstate.forget(ref.key)
        return f"{ref.name} installed"
    if action == "unused":
        # Each installation with nothing to remove says so
        nothing = sum("Nothing unused" in line for line in tail) >= len(commands)
        return "Nothing unused to remove" if nothing else "Unused runtimes removed"
    if action == "runtime":
        return f"{ref.name} can start now"
    return {"update": "Flatpaks updated", "repair": "Repair finished"}[action]


def cmd_flatpak_forget(_cfg, args):
    """Takes an app switched off here off the list."""
    flatpakstate.forget(args.get("key", ""))
    return True


def cmd_flatseal(_cfg, args):
    """Opens Flatseal, on one app's page with args.app (its `show` action takes
    an app id); starts it first when it isn't running."""
    call = ["busctl", "--user", "call", flatpakstate.FLATSEAL, "/com/github/tchx84/Flatseal",
            "org.gtk.Actions", "Activate", "sava{sv}", "show", "1", "s", args.get("app", ""), "0"]
    if args.get("app") and subprocess.run(call, capture_output=True, timeout=10).returncode == 0:
        return True
    subprocess.Popen(["flatpak", "run", flatpakstate.FLATSEAL], stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    if args.get("app"):
        # Its bus name shows up once it has started
        for _ in range(40):
            time.sleep(0.5)
            if subprocess.run(call, capture_output=True, timeout=10).returncode == 0:
                break
    return True


#--------------------------------------------------------------------#
#-- Backups
#--------------------------------------------------------------------#
def cmd_backups(cfg, _args):
    """The backups that apply to the user, each with its folder and newest copy."""
    user = loaded(cfg).resolved["users"][cfg.user]
    base = os.path.join(backupstate.ROOT, socket.gethostname())
    kinds = []
    for command, title, what, _, folder in backupstate.kinds(user):
        path = os.path.join(base, folder)
        kinds.append({"command": command, "title": title, "what": what, "folder": path,
                      "exists": os.path.isdir(path), "last": backupstate.newest(path)})
    return {"base": base, "kinds": kinds, "freetubeOpen": backupstate.freetube_open(),
            "nixm": bool(shutil.which("nixm"))}


def cmd_backup(_cfg, args):
    """Runs one backup, or all of them for "backup"; answers what nixm printed."""
    command = args.get("command")
    if command != "backup" and command not in {k[0] for k in backupstate.KINDS}:
        raise ValueError(f"unknown backup: {command}")
    try:
        ok, output = backupstate.run(command)
    except subprocess.TimeoutExpired:
        ok, output = False, "nixm took longer than 10 minutes"
    return {"ok": ok, "output": output}


#--------------------------------------------------------------------#
#-- Users
#--------------------------------------------------------------------#
def cmd_people(cfg, _args):
    """Who can log in here; adding someone is the job service's `person` job."""
    state = loaded(cfg)
    users, main = state.resolved["users"], state.resolved.get("mainUser")
    return [{"name": name, "you": name == cfg.user, "owner": name == main and len(users) > 1,
             "admin": bool(users[name].get("admin"))} for name in users]


def cmd_check_person(cfg, args):
    """Whether args.name can be added: {problem, existing}, existing when
    users/<name>/ is already set up."""
    problem, existing = peoplestate.check(cfg, list(loaded(cfg).resolved["users"]),
                                          args.get("name", "").strip())
    return {"problem": problem, "existing": existing}


#--------------------------------------------------------------------#
#-- Services and ports the running system has
#--------------------------------------------------------------------#
def cmd_services(_cfg, _args):
    """Running Now: each service in servicestate.UNITS the running system has."""
    found = servicestate.states()
    return [{"name": name, "scope": scope, "unit": unit, "active": found[(scope, unit)][0],
             "sub": found[(scope, unit)][1], "since": found[(scope, unit)][2]}
            for name, scope, unit in servicestate.UNITS if (scope, unit) in found]


def service_arg(args):
    scope, unit = args.get("scope"), args.get("unit")
    if not any(s == scope and u == unit for _, s, u in servicestate.UNITS):
        raise ValueError(f"not a service Running Now lists: {unit}")
    return scope, unit


def cmd_service_log(_cfg, args):
    try:
        return servicestate.journal(*service_arg(args))
    except subprocess.TimeoutExpired:
        raise ValueError("journalctl took too long")


def cmd_service_restart(_cfg, args):
    try:
        ok, why = servicestate.restart(*service_arg(args))
    except subprocess.TimeoutExpired:
        ok, why = False, "it took longer than 2 minutes"
    if not ok:
        raise ValueError(why)
    return True


def cmd_ports(cfg, _args):
    """What the running firewall accepts: [{proto, port, who}]."""
    state = loaded(cfg)
    return [{"proto": proto, "port": port, "who": who} for proto, port, who in system.open_ports(state.resolved)]


def package_names():
    try:
        return packagestate.cached_names()
    except subprocess.CalledProcessError as e:
        detail = (e.stderr or "").strip()
        raise OSError(detail.splitlines()[-1] if detail else str(e)) from e


def cmd_package_names(_cfg, _args):
    """How many nixpkgs names Search matches on, or {missing} without nix-search-tv."""
    if not shutil.which(packagestate.TOOL):
        return {"missing": f"{packagestate.TOOL} isn't installed"}
    return {"count": len(package_names())}


def cmd_package_search(_cfg, args):
    """The first SHOWN names matching args.query, best first, and how many match."""
    query = str(args.get("query", ""))
    hits = packagestate.search(package_names(), query)
    return {"query": query, "total": len(hits), "names": hits[:packagestate.SHOWN]}


def cmd_package_previews(_cfg, args):
    """Each of args.attrs' details as a JSON line on stderr, in order, as it's read."""
    if shutil.which(packagestate.TOOL):
        for attr in args.get("attrs") or []:
            print(json.dumps(dict(packagestate.preview(attr), attr=attr)), file=sys.stderr, flush=True)
    return {}


def cmd_reset_app(_cfg, args):
    """Resets the app of user setting args.key (an app switch) to the config's values."""
    domain, path = parse_id(args.get("key", ""))
    if domain != "user" or not resetstate.available(path):
        raise ValueError("that switch has no reset")
    resetstate.reset(path)
    return resetstate.APPS[path][0]


def cmd_doc(cfg, args):
    """One note's page (args.key, a nav id), its Markdown as blocks of Qt rich text."""
    return docstate.doc_json(cfg.flake, args.get("key", ""))


def cmd_doc_link(cfg, args):
    """Where a relative link (args.href) in note args.key leads."""
    return docstate.link(cfg.flake, args.get("key", ""), args.get("href", ""), cfg.user, cfg.machine)


def cmd_launch_options(_cfg, _args):
    return protonstate.launch_options()


def cmd_proton_versions(_cfg, _args):
    return protonstate.versions()


#--------------------------------------------------------------------#
#-- Window Rules (niri)
#--------------------------------------------------------------------#
def rules_path(cfg):
    return os.path.join(cfg.flake, wr.RULES_FILE)


def rules_editable(cfg):
    path = rules_path(cfg)
    return in_wheel() and backend.writable(cfg) and os.access(path, os.W_OK)


def match_json(match):
    return {"name": wr.window_name(match), "pattern": wr.match_pattern(match),
            "app": wr.plain(match.get("app-id", ""))}


def rule_json(rule, index):
    matches = rule.get("matches") or []
    one_app = len(matches) == 1 and "app-id" in matches[0]
    return {"index": index, "title": wr.rule_title(rule), "note": rule.get("note", ""),
            "category": rule.get("category", ""),
            "app": wr.plain(matches[0]["app-id"]) if one_app else "",
            "tags": [{"text": wr.tag_text(p, v), "kind": wr.tag_kind(p)} for p, v in wr.properties(rule)],
            "matches": [match_json(m) for m in matches],
            "excludes": [match_json(m) for m in rule.get("excludes") or []],
            "raw": rule if index is not None else None,
            "props": [{"prop": p, "value": v, "text": wr.tag_text(p, v)} for p, v in wr.properties(rule)]}


def window_json(w):
    app_id, title = w.get("app_id") or "", w.get("title") or ""
    return {"appId": app_id, "title": title, "name": wr.app_name(app_id) or app_id or title,
            "size": (w.get("layout") or {}).get("window_size") or []}


def cmd_window_rules(cfg, _args):
    """The rules in window-rules.json by group, the ones Nix sets, and the form's choices."""
    rules, from_nix, waiting = wr.listing(rules_path(cfg))
    grouped = {g[0]: [] for g in wr.GROUPS}
    for i, r in enumerate(rules):
        if "include" not in r:
            grouped[wr.group_of(r)].append(rule_json(r, i))
    workspaces, outputs = wr.places()
    categories = sorted({r["category"] for r in rules if isinstance(r.get("category"), str) and r["category"]},
                        key=str.lower)
    return {"editable": rules_editable(cfg), "waiting": waiting, "categories": categories,
            "groups": [{"title": t, "description": d, "icon": icon, "kind": k, "rules": grouped[t]}
                       for t, d, icon, k in wr.GROUPS if grouped[t]],
            "fromNix": [rule_json(r, None) for r in from_nix],
            "kinds": [{"prop": p, "title": t, "control": c, "choices": [{"label": lb, "value": v} for lb, v in ch]}
                      for p, t, _, c, ch in wr.KINDS],
            "sizes": [{"label": lb, "value": v} for lb, v in wr.SIZES],
            "workspaces": workspaces, "outputs": outputs}


def own_window(w):
    return w.get("app_id") == "dev.nixosconfig.Settings" or (
        w.get("app_id") == "org.quickshell" and w.get("title") == "Omni Settings")


def cmd_niri_windows(_cfg, _args):
    """The windows open now, but this app's own."""
    windows = [w for w in wr.niri(["windows"], 5) or [] if not own_window(w)]
    windows.sort(key=lambda w: ((w.get("app_id") or "").lower(), w.get("title") or ""))
    return [window_json(w) for w in windows]


def cmd_pick_window(_cfg, _args):
    """The window clicked next (`niri msg pick-window`), or None when cancelled."""
    w = wr.niri(["pick-window"])
    return window_json(w) if isinstance(w, dict) else None


def cmd_keybinds(_cfg, _args):
    """The binds the last build gave niri, niri's actions, the keybind changes that
    build applied, and the keys DMS's shortcut editor sets on top."""
    return {"applied": keybindstate.load_applied(), "dmsKeys": keybindstate.dms_keys()}


def cmd_launch_command(_cfg, args):
    """The command a picked window's app launches with, from its .desktop file."""
    return keybindstate.launch_command(str(args.get("appId") or ""))


def rules_to_change(cfg):
    """(the path, its rules) for a change, which only admins who can edit the files make."""
    if not rules_editable(cfg):
        raise PermissionError("only an admin who can edit the config's files changes window rules")
    path = rules_path(cfg)
    return path, wr.load(path)


def undo_dir():
    path = os.path.join(system.runtime_dir(), "window-rules-undo")
    os.makedirs(path, mode=0o700, exist_ok=True)
    return path


def save_rules(path, after, text):
    """Saves `after`, keeping the file's text before and after under a token
    the reply carries for undoWindowRules (the last 20 are kept)."""
    with open(path) as f:
        before_text = f.read()
    wr.save(path, after)
    with open(path) as f:
        after_text = f.read()
    token = f"{time.time_ns():x}"
    folder = undo_dir()
    with open(os.path.join(folder, f"{token}.json"), "w") as f:
        json.dump({"before": before_text, "after": after_text}, f)
    for old in sorted(os.listdir(folder))[:-20]:
        os.remove(os.path.join(folder, old))
    return {"text": text, "undo": token}


def cmd_add_window_rule(cfg, args):
    """Sets args.prop to args.value for the window args.appId and args.title match."""
    prop, value = args.get("prop"), args.get("value")
    if prop not in wr.KIND or value is None or value == "":
        raise ValueError("pick what the rule does")
    match = {k: args[a].strip() for k, a in (("app-id", "appId"), ("title", "title")) if (args.get(a) or "").strip()}
    if not match:
        raise ValueError("pick a window, or type an app ID or title")
    name = (args.get("name") or "").strip() or match.get("app-id") or match["title"]
    path, before = rules_to_change(cfg)
    rules = json.loads(json.dumps(before))
    wr.add_rule(rules, match, name, prop, value, (args.get("category") or "").strip()[:40])
    return save_rules(path, rules, f"{wr.property_text(prop, value)} added for {name}")


def cmd_remove_window_rule(cfg, args):
    """Takes rule args.index out of window-rules.json."""
    path, before = rules_to_change(cfg)
    index = args.get("index")
    if not isinstance(index, int) or not 0 <= index < len(before) or "include" in before[index]:
        raise ValueError("that rule isn't in the file any more")
    rules = before[:index] + before[index + 1:]
    return save_rules(path, rules, f"Removed {wr.rule_title(before[index])}")


def cmd_save_window_rule(cfg, args):
    """Replaces rule args.index with args.rule, if it is still args.original."""
    path, before = rules_to_change(cfg)
    index, rule = args.get("index"), args.get("rule")
    if not isinstance(index, int) or not 0 <= index < len(before) or before[index] != args.get("original"):
        raise ValueError("the rule changed since this page read it; open it again")
    if not isinstance(rule, dict) or not isinstance(rule.get("matches"), list) or not wr.properties(rule):
        raise ValueError("give the rule something to do, or remove it")
    rule = wr.edited(rule, before[index])
    rules = before[:index] + [rule] + before[index + 1:]
    return save_rules(path, rules, f"Saved {wr.rule_title(rule)}")


def cmd_undo_window_rules(cfg, args):
    """Puts back the file's text from before change args.token, if it still
    holds the text that change saved."""
    path, _ = rules_to_change(cfg)
    token = str(args.get("token", ""))
    saved = os.path.join(undo_dir(), f"{token}.json")
    if not token.isalnum() or not os.path.exists(saved):
        raise ValueError("there's nothing to undo")
    with open(saved) as f:
        texts = json.load(f)
    with open(path) as f:
        if f.read() != texts["after"]:
            raise ValueError("the rules changed since, so this can't be undone")
    with open(path, "w") as f:
        f.write(texts["before"])
    os.remove(saved)
    return "Undone"


COMMANDS = {"load": cmd_load, "list": cmd_list, "review": cmd_review, "save": cmd_save,
            "dismiss": cmd_dismiss,
            "stale": cmd_stale, "removeStale": cmd_remove_stale,
            "overview": cmd_overview, "freed": cmd_freed, "boot": cmd_boot,
            "checkUpdates": cmd_check_updates,
            "compare": cmd_compare, "failedLog": cmd_failed_log, "forgetFailed": cmd_forget_failed,
            "git": cmd_git, "gitSummary": cmd_git_summary, "setBackup": cmd_set_backup,
            "flatpaks": cmd_flatpaks, "flatpakUpdates": cmd_flatpak_updates, "flatpakRun": cmd_flatpak_run,
            "flatpakForget": cmd_flatpak_forget, "flatseal": cmd_flatseal,
            "backups": cmd_backups, "backup": cmd_backup,
            "people": cmd_people, "checkPerson": cmd_check_person,
            "services": cmd_services, "serviceLog": cmd_service_log, "serviceRestart": cmd_service_restart,
            "ports": cmd_ports,
            "packageNames": cmd_package_names, "packageSearch": cmd_package_search,
            "packagePreviews": cmd_package_previews,
            "resetApp": cmd_reset_app, "doc": cmd_doc, "docLink": cmd_doc_link, "launchOptions": cmd_launch_options, "protonVersions": cmd_proton_versions,
            "windowRules": cmd_window_rules, "niriWindows": cmd_niri_windows, "pickWindow": cmd_pick_window,
            "addWindowRule": cmd_add_window_rule, "removeWindowRule": cmd_remove_window_rule,
            "undoWindowRules": cmd_undo_window_rules,
            "saveWindowRule": cmd_save_window_rule,
            "keybinds": cmd_keybinds, "launchCommand": cmd_launch_command}


def run(cfg, cmd, args):
    """One command's reply as a dict."""
    fn = COMMANDS.get(cmd)
    if fn is None:
        return {"ok": False, "error": f"unknown command: {cmd}"}
    try:
        return {"ok": True, "data": fn(cfg, args if isinstance(args, dict) else {})}
    except backend.SettingsError as e:
        return {"ok": False, "error": str(e), "settings": True}
    except (OSError, ValueError, PermissionError, nixfile.NixError, system.UpdateError) as e:
        return {"ok": False, "error": str(e)}
    except Exception as e:  # noqa: BLE001 - the front end always gets a reply
        return {"ok": False, "error": f"{type(e).__name__}: {e}"}


def serve():
    """`--serve`: Backend.qml's requests as JSON lines on stdin, {"id", "cmd", "args"},
    each run in a forked child, so it starts as a fresh call would minus the imports;
    the replies go to stdout as {"id", "reply"} lines, in the order they finish."""
    sel = selectors.DefaultSelector()
    sel.register(0, selectors.EVENT_READ)
    pending = b""
    children = {}  # read end -> [request id, pid, reply bytes]
    while True:
        for key, _ in sel.select():
            fd = key.fd
            if fd == 0:
                chunk = os.read(0, 65536)
                if not chunk:
                    return
                *lines, pending = (pending + chunk).split(b"\n")
                for line in lines:
                    if line.strip():
                        r, pid, rid = fork_request(line)
                        children[r] = [rid, pid, b""]
                        sel.register(r, selectors.EVENT_READ)
                continue
            chunk = os.read(fd, 65536)
            if chunk:
                children[fd][2] += chunk
                continue
            rid, pid, data = children.pop(fd)
            sel.unregister(fd)
            os.close(fd)
            os.waitpid(pid, 0)
            if not data:
                data = json.dumps({"ok": False, "error": "omni-settings-backend gave no answer"}).encode()
            sys.stdout.buffer.write(b'{"id": %s, "reply": %s}\n' % (json.dumps(rid).encode(), data))
            sys.stdout.buffer.flush()


def fork_request(line):
    """A child running one serve() request; its read end, pid and the request's id."""
    try:
        req = json.loads(line)
        rid, cmd, args = req.get("id"), req.get("cmd", ""), req.get("args") or {}
    except (ValueError, AttributeError):
        rid, cmd, args = None, "", {}
    r, w = os.pipe()
    pid = os.fork()
    if pid:
        os.close(w)
        return r, pid, rid
    try:
        os.close(r)
        # Nothing a command runs may read the requests or write into the replies
        null = os.open(os.devnull, os.O_RDWR)
        os.dup2(null, 0)
        os.dup2(null, 1)
        data = json.dumps(run(backend.Config.from_env(), cmd, args)).encode()
        while data:
            data = data[os.write(w, data):]
    finally:
        os._exit(0)


def main():
    if sys.argv[1:] == ["--serve"]:
        serve()
        return
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
