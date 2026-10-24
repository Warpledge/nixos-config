"""Where the config repo stands, read-only: branch, changed files, commits to
push and pull, recent commits, and open pull requests from GitHub's API (signed
in through gh when it is)."""

import calendar
import json
import os
import re
import shutil
import subprocess
import time
import urllib.error
import urllib.request

import system

#--- No password or passphrase prompt can hang a read
ENV = dict(os.environ, GIT_TERMINAL_PROMPT="0", GIT_SSH_COMMAND="ssh -o BatchMode=yes")
GITHUB = re.compile(r"github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?/?$")
LOG = "--format=%h%x1f%H%x1f%s%x1f%an%x1f%ct"
STATES = {"M": "modified", "A": "added", "D": "deleted", "R": "renamed", "C": "copied", "?": "new",
          "U": "conflict"}
MAX_FILES = 50
#--- Seconds between fetches and GitHub calls; the local counts refresh every minute
REMOTE_EVERY = 300
FORCED_EVERY = 30


def git(flake, *args, timeout=20):
    out = subprocess.run(["git", "-C", flake, *args], capture_output=True, text=True, timeout=timeout,
                         env=ENV, stdin=subprocess.DEVNULL)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or f"git {args[0]} failed")
    return out.stdout


def github_repo(flake):
    """"owner/name" of the origin remote on GitHub, or None."""
    try:
        m = GITHUB.search(git(flake, "remote", "get-url", "origin").strip())
    except (RuntimeError, OSError, subprocess.TimeoutExpired):
        return None
    return f"{m.group(1)}/{m.group(2)}" if m else None


def commits(flake, *rev):
    return [line.split("\x1f") for line in git(flake, "log", LOG, *rev).splitlines() if line]


def last_fetch(flake):
    try:
        return os.path.getmtime(os.path.join(flake, git(flake, "rev-parse", "--git-path", "FETCH_HEAD").strip()))
    except (RuntimeError, OSError):
        return None


def snapshot(flake):
    status = system.git_status(flake)
    changed = [line for line in git(flake, "status", "--porcelain").splitlines() if line]
    upstream = git(flake, "rev-parse", "--abbrev-ref", "@{u}").strip() if status.upstream else ""
    outgoing = commits(flake, "@{u}..HEAD") if upstream else []
    incoming = commits(flake, "HEAD..@{u}") if upstream else []
    return status, upstream, changed, outgoing, incoming, commits(flake, "-15"), last_fetch(flake)


def pull_requests(repo):
    req = urllib.request.Request(f"https://api.github.com/repos/{repo}/pulls?state=open&per_page=30",
                                 headers={"Accept": "application/vnd.github+json"})
    if shutil.which("gh"):
        out = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True, timeout=10)
        if out.returncode == 0 and out.stdout.strip():
            req.add_header("Authorization", f"Bearer {out.stdout.strip()}")
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def cache_path():
    return os.path.join(system.runtime_dir(), "git-remote.json")


def remote(flake, repo, force=False):
    """Fetches and reads the open PRs, then hands back (fetch error, PRs, PR
    error, whether GitHub's limit is used up). Within REMOTE_EVERY of the last
    check (FORCED_EVERY for Refresh) it hands back that check's results, kept in
    a file both front ends share, staying under GitHub's 60 requests an hour
    without signing in."""
    try:
        with open(cache_path()) as f:
            cached = json.load(f)
    except (OSError, ValueError):
        cached = {"at": 0}
    if time.time() - cached.get("at", 0) >= (FORCED_EVERY if force else REMOTE_EVERY):
        cached = {"at": time.time(), "fetchErr": None, "prs": None, "prErr": None, "limited": False}
        try:
            git(flake, "fetch", "--quiet", timeout=60)
        except (RuntimeError, OSError, subprocess.TimeoutExpired) as e:
            cached["fetchErr"] = str(e)
        if repo:
            try:
                cached["prs"] = pull_requests(repo)
            except urllib.error.HTTPError as e:
                cached["prErr"], cached["limited"] = str(e), e.code == 403
            except (OSError, ValueError, subprocess.TimeoutExpired) as e:
                cached["prErr"] = str(e)
        try:
            with open(cache_path(), "w") as f:
                json.dump(cached, f)
        except OSError:
            pass
    return cached.get("fetchErr"), cached.get("prs"), cached.get("prErr"), cached.get("limited", False)


def summary(flake):
    """The page list's counts; prs is left out when GitHub can't be read."""
    _, prs, _, _ = remote(flake, github_repo(flake))
    status = system.git_status(flake)
    counts = {"changed": status.changed, "ahead": status.ahead, "behind": status.behind}
    if prs is not None:
        counts["prs"] = len(prs)
    return counts


def iso_epoch(text):
    try:
        return calendar.timegm(time.strptime(text, "%Y-%m-%dT%H:%M:%SZ"))
    except (TypeError, ValueError):
        return None
