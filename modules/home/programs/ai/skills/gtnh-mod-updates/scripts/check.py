#!/usr/bin/env python3
"""Check hand-added GTNH mods for new versions. Read-only.

Prints a table and writes the details (changelogs, download URLs, hashes) to a JSON file
for install.py and the report.
"""
import argparse
import concurrent.futures
import glob
import hashlib
import json
import os
import re
import socket
import subprocess
import sys
import urllib.parse
import urllib.request

UA = "gtnh-mod-updates (github.com/Warpledge/nixos-config)"
INSTANCES = "~/.local/share/PrismLauncher/instances/GT_New_Horizons_*"
OMNI_SERVERS = "~/.config/omni-server/servers/gtnh-*.json"
SERVERS = "~/Documents/Minecraft_Servers/GT_New_Horizons_*_Server_Modified"
MANIFESTS = "repos/GTNewHorizons/DreamAssemblerXXL/contents/releases/manifests"
RAW_MANIFEST = ("https://raw.githubusercontent.com/GTNewHorizons/DreamAssemblerXXL/"
                "master/releases/manifests/{}.json")
NOT_THE_MOD = re.compile(r"-(dev|sources|api|javadoc|predowngrade|preshadow|dev-preshadow)\.jar$")
BODY_LIMIT = 4000


def http_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def gh(path):
    out = subprocess.run(["gh", "api", path], capture_output=True, text=True, timeout=60)
    if out.returncode:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    return json.loads(out.stdout)


def find_instance(given):
    if given:
        return given
    found = sorted(glob.glob(os.path.expanduser(INSTANCES)), key=os.path.getmtime)
    if not found:
        sys.exit("No GT_New_Horizons_* instance in PrismLauncher.")
    return found[-1]


def find_server(given):
    """The server folder with a mods/ on this machine, or None."""
    if given:
        return given
    dirs = []
    for path in glob.glob(os.path.expanduser(OMNI_SERVERS)):
        with open(path) as f:
            dirs.append(json.load(f).get("dir", ""))
    dirs += glob.glob(os.path.expanduser(SERVERS))
    found = [d for d in dirs if os.path.isdir(os.path.join(d, "mods"))]
    return max(found, key=os.path.getmtime) if found else None


def pack_version(folder):
    m = re.search(r"GT_New_Horizons_(\d+(?:\.\d+)+)", folder)
    return m.group(1) if m else None


def version_key(v):
    return tuple(int(x) for x in v.split("."))


def find_sources(given):
    """Read before the pack is known, since it says which folder holds the pack's mods."""
    if given:
        return given
    top = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    repo = top.stdout.strip() or os.getcwd()
    found = glob.glob(f"{repo}/docs/personal/gaming/minecraft_servers/GTNH/*/mod-sources.json")
    if not found:
        sys.exit("No GTNH mod-sources.json in this repo's docs/personal.")
    return max(found, key=lambda p: version_key(os.path.basename(os.path.dirname(p))))


def clean(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def has_version(text, version):
    """True when version, with or without a leading v, sits between non-alphanumerics."""
    return bool(re.search(rf"(?<![0-9A-Za-z.])v?{re.escape(version)}(?![0-9A-Za-z])", text))


def stem(jar):
    return re.split(r"[-_.]", jar)[0].lower()


def entry(version, date, prerelease, url, body, asset=None, sha=None, size=None):
    return {"version": version, "date": date, "prerelease": prerelease, "url": url,
            "changelog": (body or "")[:BODY_LIMIT], "asset": asset, "hash": sha, "size": size}


def pick_asset(assets, mod, jar):
    jars = [a for a in assets if a["name"].endswith(".jar") and not NOT_THE_MOD.search(a["name"])]
    if mod.get("asset"):
        jars = [a for a in jars if re.search(mod["asset"], a["name"])]
    elif jar:
        jars = [a for a in jars if a["name"].lower().startswith(stem(jar))]
    return jars[0] if jars else None


#-- Each source returns every version, newest first, and the installed one if known

def check_github(repo, mod, jar):
    releases = gh(f"repos/{repo}/releases?per_page=100")
    rows, installed = [], None
    for r in releases:
        a = pick_asset(r["assets"], mod, jar)
        if not a:
            continue
        digest = a.get("digest") or ""
        row = entry(r["tag_name"], r["published_at"], r["prerelease"], r["html_url"], r["body"],
                    {"name": a["name"], "url": a["browser_download_url"]},
                    digest if digest.startswith("sha256:") else None, a["size"])
        rows.append(row)
        if jar and a["name"] == jar:
            installed = row["version"]
    rows.sort(key=lambda r: r["date"], reverse=True)
    base = jar or mod.get("lastTried") or ""
    if not installed:
        # Longest tag first, so 1.0.6 can't match as 1.0
        for row in sorted(rows, key=lambda r: -len(r["version"])):
            if has_version(base, row["version"].lstrip("v")):
                installed = row["version"]
                break
    if not rows:
        tags = gh(f"repos/{repo}/tags?per_page=5")
        for t in tags:
            rows.append(entry(t["name"], "", False, f"https://github.com/{repo}/tree/{t['name']}",
                              "Tag only, no release with a jar."))
        if rows and has_version(base, rows[0]["version"].lstrip("v")):
            installed = rows[0]["version"]
    return rows, installed, f"https://github.com/{repo}/releases"


def check_modrinth(slug, jar_path):
    query = urllib.parse.urlencode({"game_versions": '["1.7.10"]', "loaders": '["forge"]'})
    versions = http_json(f"https://api.modrinth.com/v2/project/{slug}/version?{query}")
    rows = []
    sha1 = None
    if jar_path:
        with open(jar_path, "rb") as f:
            sha1 = hashlib.sha1(f.read()).hexdigest()
    installed = None
    for v in versions:
        primary = next((f for f in v["files"] if f["primary"]), v["files"][0])
        rows.append(entry(v["version_number"], v["date_published"], v["version_type"] != "release",
                          f"https://modrinth.com/mod/{slug}/version/{v['id']}", v["changelog"],
                          {"name": primary["filename"], "url": primary["url"]},
                          f"sha512:{primary['hashes']['sha512']}", primary["size"]))
        if sha1 and any(f["hashes"].get("sha1") == sha1 for f in v["files"]):
            installed = v["version_number"]
    rows.sort(key=lambda r: r["date"], reverse=True)
    return rows, installed, f"https://modrinth.com/mod/{slug}/versions"


def check_curseforge(slug, jar):
    data = http_json(f"https://api.cfwidget.com/minecraft/mc-mods/{slug}")
    rows, installed = [], None
    for f in data.get("versions", {}).get("1.7.10", []):
        fid = str(f["id"])
        url = (f"https://mediafilez.forgecdn.net/files/{fid[:4]}/{int(fid[4:])}/"
               f"{urllib.parse.quote(f['name'])}")
        rows.append(entry(f["name"], f["uploaded_at"], f.get("type") != "release", f["url"],
                          "CurseForge's public widget has no changelog; see the file's page.",
                          {"name": f["name"], "url": url}, None, f.get("filesize")))
        if jar and f["name"] == jar:
            installed = f["name"]
    rows.sort(key=lambda r: r["date"], reverse=True)
    return rows, installed, f"https://www.curseforge.com/minecraft/mc-mods/{slug}/files"


def check_pinned(repo, mod):
    """A repo tracked by commit, for files that aren't jars. Only `paths` matches count."""
    pin = mod["pin"]
    diff = gh(f"repos/{repo}/compare/{pin}...HEAD")
    result = {"installed": pin[:7], "page": f"https://github.com/{repo}/commits"}
    files = [f["filename"] for f in diff.get("files", [])]
    if mod.get("paths"):
        files = [f for f in files if re.search(mod["paths"], f)]
    if not diff["ahead_by"] or not files:
        return {**result, "state": "current"}
    commits = diff["commits"][::-1]
    log = "\n".join(c["commit"]["message"].split("\n")[0] for c in commits)
    head = commits[0]
    return {**result, "state": "pinned-newer", "newer": [
        entry(head["sha"][:7], head["commit"]["committer"]["date"], False, diff["html_url"],
              f"{diff['ahead_by']} commits. Files: {', '.join(files)}\n{log}")]}


#-- One mod's result

def check_mod(mod, jars, mods_dir):
    source = mod["source"]
    kind, _, where = source.partition(":")
    parked = mod.get("status") == "parked"
    jar = None
    if kind == "pinned":
        try:
            return {**mod, "jar": None, "newer": [], **check_pinned(where, mod)}
        except Exception as e:
            return {**mod, "jar": None, "newer": [], "state": "failed", "error": str(e)[:300]}
    if not parked:
        names = [j for j in jars if re.search(mod["jar"], j)]
        if not names:
            return {**mod, "state": "missing", "jar": None, "newer": []}
        jar = sorted(names, key=lambda j: j.endswith(".disabled"))[0]
    result = {**mod, "jarPattern": mod.get("jar"), "jar": jar, "newer": [],
              "disabled": bool(jar and jar.endswith(".disabled"))}
    live_jar = jar[:-len(".disabled")] if result["disabled"] else jar
    if kind == "none":
        return {**result, "state": "no-source"}
    if kind == "local":
        return {**result, "state": "local"}
    try:
        if kind == "github":
            rows, installed, page = check_github(where, mod, live_jar)
        elif kind == "modrinth":
            path = os.path.join(mods_dir, jar) if jar else None
            rows, installed, page = check_modrinth(where, path)
            if not installed and jar:
                for row in sorted(rows, key=lambda r: -len(r["version"])):
                    if has_version(live_jar, row["version"]):
                        installed = row["version"]
                        break
        elif kind == "curseforge":
            rows, installed, page = check_curseforge(where, live_jar)
        else:
            raise RuntimeError(f"unknown source {source}")
    except Exception as e:
        return {**result, "state": "failed", "error": str(e)[:300]}
    result.update(page=page, installed=installed)
    if not rows:
        return {**result, "state": "failed", "error": "no 1.7.10 builds listed"}
    latest = rows[0]
    if not installed:
        return {**result, "state": "baseline-unknown", "newer": [latest]}
    base = next(r for r in rows if r["version"] == installed)
    newer = [r for r in rows if r["date"] > base["date"]]
    state = "update" if newer else "current"
    if newer and all(r["prerelease"] for r in newer) and not base["prerelease"]:
        state = "prerelease-only"
    return {**result, "state": state, "newer": newer}


#-- Drift against the pack and newer pack releases

def stable_packs():
    packs = [f["name"][:-5] for f in gh(MANIFESTS) if re.fullmatch(r"\d+(\.\d+)+\.json", f["name"])]
    return sorted(packs, key=version_key)


def manifest_mods(pack):
    data = http_json(RAW_MANIFEST.format(pack))
    return {**data["github_mods"], **data["external_mods"]}


def pack_owns(jar, manifest):
    jar_clean = clean(jar)
    for key, mod in manifest.items():
        if has_version(jar, mod["version"]) and (
                clean(key)[:5] in jar_clean or jar_clean[:5] in clean(key)):
            return True
    return False


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--role", choices=["client", "server"],
                    help="what to check (default: this machine's role in mod-sources.json)")
    ap.add_argument("--instance", help="Prism instance folder (default: newest GTNH one)")
    ap.add_argument("--server", help="server folder (default: found on this machine)")
    ap.add_argument("--sources", help="mod-sources.json (default: newest pack's in docs/)")
    ap.add_argument("--out", help="report path (default: $XDG_RUNTIME_DIR)")
    args = ap.parse_args()

    with open(find_sources(args.sources)) as f:
        sources = json.load(f)
    machines = sources.get("machines", {})
    host = socket.gethostname()
    role = args.role or machines.get(host)
    if not role:
        sys.exit(f"{host} isn't under machines in mod-sources.json; pass --role client or server.")

    server = find_server(args.server)
    if role == "server":
        if not server:
            sys.exit("No GTNH server folder with a mods/ on this machine.")
        instance, mods_dir, pack = None, os.path.join(server, "mods"), pack_version(server)
        # A server has no use for client-only mods, so they aren't checked at all
        wanted = [m for m in sources["mods"] if m["side"] == "B"]
    else:
        instance = find_instance(args.instance)
        mods_dir, pack = os.path.join(instance, ".minecraft", "mods"), pack_version(instance)
        wanted = sources["mods"]
    out = args.out or os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "gtnh-mod-updates.json")

    jars = sorted(j for j in os.listdir(mods_dir) if j.endswith((".jar", ".jar.disabled")))
    with concurrent.futures.ThreadPoolExecutor(8) as pool:
        results = list(pool.map(lambda m: check_mod(m, jars, mods_dir), wanted))

    report = {"role": role, "machines": machines, "instance": instance, "serverDir": server,
              "pack": pack, "modsDir": mods_dir, "mods": results,
              "unmapped": [], "packError": None, "newerPack": None, "packNowShips": []}
    try:
        manifest = manifest_mods(pack)
        mapped = [m["jar"] for m in sources["mods"] if m.get("jar")] + sources.get("ignore", [])
        report["unmapped"] = [j for j in jars if j.endswith(".jar")
                              and not any(re.search(p, j) for p in mapped)
                              and not pack_owns(j, manifest)]
        newest = stable_packs()[-1]
        newest_mods = manifest
        if version_key(newest) > version_key(pack):
            report["newerPack"] = newest
            newest_mods = manifest_mods(newest)
        keys = {clean(k): k for k in newest_mods}
        for m in results:
            repo = m["source"].rpartition("/")[2]
            hit = keys.get(clean(m["name"])) or keys.get(clean(repo))
            if hit:
                report["packNowShips"].append(
                    {"mod": m["name"], "packEntry": hit, "version": newest_mods[hit]["version"]})
    except Exception as e:
        report["packError"] = str(e)[:300]

    with open(out, "w") as f:
        json.dump(report, f, indent=1, ensure_ascii=False)

    order = ["update", "prerelease-only", "pinned-newer", "baseline-unknown", "failed", "missing", "no-source",
             "local", "current"]
    for m in sorted(results, key=lambda m: order.index(m["state"])):
        latest = m["newer"][0]["version"] if m["newer"] else "-"
        have = m.get("installed") or m.get("lastTried") or m.get("jar") or "-"
        tag = " [parked]" if m.get("status") == "parked" else " [disabled]" if m.get("disabled") else ""
        print(f"{m['state']:<17} {m['name'] + tag:<38} {str(have)[:34]:<35} {latest[:34]}")
    print(f"\n{host} as {role}: {mods_dir}")
    if role == "client" and server:
        print(f"Debug server on this machine: {server}")
    print(f"Pack {pack}; newer stable pack: {report['newerPack'] or 'none'}")
    for key in ("unmapped", "packNowShips", "packError"):
        if report[key]:
            print(f"{key}: {report[key]}")
    print(f"Report: {out}")


if __name__ == "__main__":
    main()
