"""Upstream release notes between the old and new version of a flake input, from
GitHub's API (signed in through gh when it is). Releases published in between
come first; a repo that makes none is listed by its commits instead. Each
answer is kept for a day in the runtime directory, since GitHub allows 60 reads
an hour without signing in."""

import json
import os
import re
import time
import urllib.error

import gitstate
import system

REPO = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
REV = re.compile(r"^[0-9a-f]{7,40}$")
MAX_RELEASES = 40  # newest first; a version of an input rarely has more
MAX_BODY = 6000  # characters of one release's notes
KEEP = 24 * 3600


class NotesError(ValueError):
    pass


def _when(text):
    return gitstate.iso_epoch(text or "")


def _cache_path(repo, before, after):
    safe = re.sub(r"[^A-Za-z0-9_.-]", "-", f"{repo}-{before[:8]}-{after[:8]}")
    return os.path.join(system.runtime_dir(), f"notes-{safe}.json")


def clean(text):
    """A release's Markdown as plain text; the link opens the rest."""
    lines = []
    for line in (text or "").splitlines():
        line = line.rstrip().replace("**", "").replace("__", "").replace("`", "")
        line = re.sub(r"^\s{0,3}#{1,6}\s*", "", line)
        line = re.sub(r"^\s*[-*]\s+", "• ", line)
        lines.append(line)
    return re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip()[:MAX_BODY]


def releases(repo, old, new):
    """The notes published between two of an input's versions, newest first."""
    found = []
    for page in range(1, 4):  # 300 releases back is more than a version's worth
        batch = gitstate.github(f"repos/{repo}/releases?per_page=100&page={page}")
        if not isinstance(batch, list):
            break
        found += batch
        if not batch:
            break
        oldest = min((_when(r.get("published_at") or r.get("created_at")) or 0) for r in batch)
        if len(batch) < 100 or oldest <= old:
            break
    picked, seen = [], set()
    for release in found:
        at = _when(release.get("published_at") or release.get("created_at"))
        tag = release.get("tag_name", "")
        if at is None or at <= old or at > new or tag in seen:
            continue
        seen.add(tag)
        picked.append({"tag": tag, "name": release.get("name") or tag, "when": at,
                       "body": clean(release.get("body")), "url": release.get("html_url", "")})
    return picked[:MAX_RELEASES]


def commits(repo, before, after):
    """The commits between two revisions, as {total, items}, for a repo without
    releases."""
    data = gitstate.github(f"repos/{repo}/compare/{before}...{after}")
    items = [{"sha": c.get("sha", "")[:9],
              "subject": (c.get("commit", {}).get("message") or "").splitlines()[0],
              "when": _when(c.get("commit", {}).get("author", {}).get("date")),
              "url": c.get("html_url", "")}
             for c in (data.get("commits") or [])]
    return {"total": data.get("total_commits", len(items)), "items": items[-100:]}


def notes(repo, before, after, old, new):
    """{repo, releases, commits, url} for one input, from the cache when it's fresh."""
    if not REPO.match(repo or ""):
        raise NotesError("this source isn't on GitHub, so it has no release notes to read")
    if not (REV.match(before or "") and REV.match(after or "")):
        raise NotesError("the source check didn't keep this input's revisions")
    path = _cache_path(repo, before, after)
    try:
        with open(path) as f:
            cached = json.load(f)
        if time.time() - cached.get("at", 0) < KEEP:
            return cached["notes"]
    except (OSError, ValueError, KeyError):
        pass
    result = {"repo": repo, "releases": [], "commits": None, "url": f"https://github.com/{repo}"}
    try:
        result["releases"] = releases(repo, old or 0, new or time.time())
        if not result["releases"]:
            result["commits"] = commits(repo, before, after)
    except urllib.error.HTTPError as e:
        raise NotesError(_why(e, repo))
    except (OSError, ValueError) as e:
        raise NotesError(f"couldn't read {repo}'s notes: {e}") from e
    try:
        with open(path, "w") as f:
            json.dump({"at": time.time(), "notes": result}, f)
    except OSError:
        pass
    return result


def _why(error, repo):
    if error.code == 403:
        return "GitHub's hourly limit for reading it is used up; try again in a few minutes."
    if error.code == 404:
        return f"{repo} isn't on GitHub any more."
    return f"GitHub answered {error.code} for {repo}."
