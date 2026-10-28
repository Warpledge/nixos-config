"""Where the config repo stands: branch, changed files, commits to push and
pull, recent commits, the commit count, and open pull requests from GitHub's
API (signed in through gh when it is). The one write is `pull`, for the
Overview's pull job."""

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


def commit_count(flake):
    """How many commits HEAD has, for the Git page's count."""
    return int(git(flake, "rev-list", "--count", "HEAD").strip() or 0)


def last_fetch(flake):
    try:
        return os.path.getmtime(os.path.join(flake, git(flake, "rev-parse", "--git-path", "FETCH_HEAD").strip()))
    except (RuntimeError, OSError):
        return None


def snapshot(flake):
    status = system.git_status(flake)
    changed = [line for line in git(flake, "status", "--porcelain").splitlines() if line]
    upstream = git(flake, "rev-parse", "--abbrev-ref", "@{u}").strip() if status.upstream else ""
    outgoing = commits(flake, f"{system.push_ref(flake)}..HEAD") if upstream else []
    incoming = commits(flake, "HEAD..@{u}") if upstream else []
    return (status, upstream, changed, outgoing, incoming, commits(flake, "-15"), last_fetch(flake),
            commit_count(flake))


def github(path, timeout=15):
    """One GitHub REST read, signed in through gh when it is."""
    req = urllib.request.Request(f"https://api.github.com/{path}",
                                 headers={"Accept": "application/vnd.github+json"})
    if shutil.which("gh"):
        out = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True, timeout=10)
        if out.returncode == 0 and out.stdout.strip():
            req.add_header("Authorization", f"Bearer {out.stdout.strip()}")
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def pull_requests(repo):
    return github(f"repos/{repo}/pulls?state=open&per_page=30")


def cache_path():
    return os.path.join(system.runtime_dir(), "git-remote.json")


def remote(flake, repo, force=False, cached_only=False):
    """Fetches and reads the open PRs, then hands back (fetch error, PRs, PR
    error, whether GitHub's limit is used up). Within REMOTE_EVERY of the last
    check (FORCED_EVERY for Refresh), or with cached_only, it hands back that
    check's results, kept in a file both front ends share, staying under
    GitHub's 60 requests an hour without signing in."""
    try:
        with open(cache_path()) as f:
            cached = json.load(f)
    except (OSError, ValueError):
        cached = {"at": 0}
    if not cached_only and time.time() - cached.get("at", 0) >= (FORCED_EVERY if force else REMOTE_EVERY):
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


#--------------------------------------------------------------------#
#-- Pull
#--------------------------------------------------------------------#
class PullError(Exception):
    pass


def changed_between(flake, path, *revs):
    """Whether `path` differs between `revs` (the working tree when one rev)."""
    out = subprocess.run(["git", "-C", flake, "diff", "--quiet", *revs, "--", path], env=ENV,
                         stdin=subprocess.DEVNULL, timeout=20)
    return out.returncode == 1


def pull(flake):
    """Fetches the branch's upstream and rebases the local commits onto it, as
    `git pull --rebase` does, or merges it when a local commit is a merge (a
    fork that merges upstream, whose resolved conflicts a rebase would replay),
    setting uncommitted changes aside meanwhile. A flake.lock changed both here
    (an Update not committed) and upstream takes the upstream's. Returns (old
    HEAD, the replaced flake.lock text or None) for `unpull`."""
    try:
        git(flake, "fetch", "--quiet", timeout=120)
        old = git(flake, "rev-parse", "HEAD").strip()
        lock = None
        if changed_between(flake, "flake.lock", "HEAD") and changed_between(flake, "flake.lock", "HEAD...@{u}"):
            with open(os.path.join(flake, "flake.lock")) as f:
                lock = f.read()
            git(flake, "checkout", "HEAD", "--", "flake.lock")
        mode = "merge" if git(flake, "rev-list", "--merges", "@{u}..HEAD").strip() else "rebase"
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as e:
        raise PullError(str(e))
    args = ["merge", "--autostash", "--no-edit", "@{u}"] if mode == "merge" else ["rebase", "--autostash", "@{u}"]
    out = subprocess.run(["git", "-C", flake, *args], capture_output=True, text=True,
                         env=dict(ENV, GIT_EDITOR="true"), stdin=subprocess.DEVNULL, timeout=120)
    if out.returncode != 0:
        conflicts = subprocess.run(["git", "-C", flake, "diff", "--name-only", "--diff-filter=U"],
                                   capture_output=True, text=True, env=ENV, timeout=20).stdout.split()
        subprocess.run(["git", "-C", flake, mode, "--abort"], capture_output=True, env=ENV, timeout=60)
        unpull(flake, None, lock)
        raise PullError(f"Your commits clash with the new ones in {', '.join(conflicts)}; nothing was changed."
                        if conflicts else out.stderr.strip() or f"git {mode} failed")
    return old, lock


def unpull(flake, old, lock):
    """Puts the branch back at `old` and flake.lock back to `lock`."""
    if old:
        git(flake, "reset", "--keep", old)
    if lock is not None:
        with open(os.path.join(flake, "flake.lock"), "w") as f:
            f.write(lock)


def push_remote(flake):
    """(branch, remote) when the branch pushes somewhere other than it pulls
    from (branch.<name>.pushRemote or remote.pushDefault), else None."""
    try:
        branch = git(flake, "branch", "--show-current").strip()
        upstream = git(flake, "config", f"branch.{branch}.remote").strip()
    except RuntimeError:
        return None
    for key in (f"branch.{branch}.pushRemote", "remote.pushDefault"):
        try:
            push = git(flake, "config", key).strip()
        except RuntimeError:
            continue
        return (branch, push) if push and push != upstream else None
    return None


def push_backup(flake):
    """Pushes the branch to its push remote, when it has one apart from the
    upstream. Returns a line for the log, or None when there's nowhere to push."""
    target = push_remote(flake)
    if target is None:
        return None
    branch, push = target
    # Set by set_backup: what this clone last pushed ("none" for a new repo),
    # so another computer's push is refused rather than replaced
    try:
        last = git(flake, "config", f"branch.{branch}.omniBackedUp").strip()
    except RuntimeError:
        last = ""
    lease = f"--force-with-lease={branch}:{'' if last == 'none' else last}" if last else "--force-with-lease"
    try:
        # Pull can rebase the local commits, so the push replaces the old ones
        git(flake, "push", "--quiet", lease, push, f"HEAD:{branch}", timeout=120)
        if last:
            git(flake, "config", f"branch.{branch}.omniBackedUp", git(flake, "rev-parse", "HEAD").strip())
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        if last and ("stale info" in str(e) or "rejected" in str(e)):
            return (f"Didn't back up to {push}: something else pushed there since this computer last "
                    "did, and it was left alone. Give each computer its own backup repo.")
        return f"Couldn't back up to {push}: {e}"
    return f"Backed up your changes to {push}"


def back_up(flake, machine, paths):
    """After a successful run, on a clone with a push remote: commits what
    changed under `paths` (this machine's and this user's folders), then
    pushes. Returns a line for the log, or None when there's no push remote."""
    if push_remote(flake) is None:
        return None
    paths = [p for p in paths if os.path.isdir(os.path.join(flake, p))]
    if not paths:  # with no paths, add and commit would take the whole tree
        return "Didn't back up: this machine's and user's folders aren't there."
    try:
        git(flake, "add", "-A", "--", *paths)
        staged = subprocess.run(["git", "-C", flake, "diff", "--cached", "--quiet", "--", *paths], env=ENV,
                                stdin=subprocess.DEVNULL, timeout=20)
        if staged.returncode == 1:
            git(flake, "commit", "--quiet", "-m", f"chore({machine}): save settings from Omni Settings",
                "--", *paths)
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        return f"Couldn't commit your changes: {e}"
    return push_backup(flake)


def backup_url(flake):
    """The URL the branch backs up to (its separate push remote), or ""."""
    target = push_remote(flake)
    if target is None:
        return ""
    try:
        return git(flake, "remote", "get-url", target[1]).strip()
    except RuntimeError:
        return ""


def set_backup(flake, machine, paths, url):
    """Points the branch's pushes at `url` through a `backup` remote, then backs
    up `paths` there; an empty `url` stops the backups. Returns a line to show."""
    try:
        branch = git(flake, "branch", "--show-current").strip()
        if not url:
            subprocess.run(["git", "-C", flake, "config", "--unset", f"branch.{branch}.pushRemote"],
                           env=ENV, capture_output=True, timeout=20)
            still = push_remote(flake)
            if still:
                return (f"Still pushing to {still[1]}, set by remote.pushDefault; "
                        "`git config --unset remote.pushDefault` stops that.")
            return "Backups are off."
        if not re.match(r"^(https://|ssh://|git@)\S+$", url):
            raise PullError("Paste the repo's https:// or git@ address.")
        if git(flake, "config", f"branch.{branch}.remote").strip() == "backup":
            raise PullError("This branch pulls from the remote named backup; rename that remote first.")
        # Only an empty repo, or one holding this clone's own last backup, so
        # nothing already there gets overwritten
        there = git(flake, "ls-remote", url, f"refs/heads/{branch}", timeout=120).split()
        try:
            last = git(flake, "config", f"branch.{branch}.omniBackedUp").strip()
        except RuntimeError:
            last = ""
        if there and there[0] != last:
            raise PullError(f"That repo already has a {branch} branch, so backing up would replace it. "
                            "Paste an empty repo.")
        if not there:
            git(flake, "config", f"branch.{branch}.omniBackedUp", "none")
        if "backup" in git(flake, "remote").split():
            git(flake, "remote", "set-url", "backup", url)
        else:
            git(flake, "remote", "add", "backup", url)
        git(flake, "config", f"branch.{branch}.pushRemote", "backup")
        git(flake, "fetch", "--quiet", "backup", timeout=120)
    except (RuntimeError, subprocess.TimeoutExpired) as e:
        raise PullError(str(e))
    return back_up(flake, machine, paths)


def iso_epoch(text):
    try:
        return calendar.timegm(time.strptime(text, "%Y-%m-%dT%H:%M:%SZ"))
    except (TypeError, ValueError):
        return None
