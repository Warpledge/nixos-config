---
name: upstream
description: Keep a fork of this NixOS repo in step with warpledge's (Warpledge/nixos-config) and prepare pull requests back to it. Use in someone else's copy of the repo when they ask to pull in, sync or merge upstream changes, to send, share or PR a module or fix upstream, or when a merge from upstream conflicts.
---

# Fork and upstream

A fork's own `machines/<name>/` and `users/<name>/` stay in the fork; shared work in
`modules/`, `lib/`, the templates, `setup.sh` and the docs can go upstream. Upstream
never touches the fork's folders, so syncing only conflicts where both sides edited a
shared file.

## 0. Check the remotes

```bash
git remote -v
```

- `origin` is `Warpledge/nixos-config` itself: this is warpledge's own copy, so there's
  nothing to sync or send. Stop.
- No `upstream` remote: ask, then add it with
  `git remote add upstream https://github.com/Warpledge/nixos-config.git`.

## Sync from upstream

1. `git status --short` must be clean apart from untracked files; commit first (the
   `commit` skill).
2. `git fetch upstream`, then `git log --oneline HEAD..upstream/main` to show what's
   coming in.
3. `git merge upstream/main`. Don't rebase: the fork's history is published.
4. Conflicts:
   - `flake.lock`: take upstream's (`git checkout --theirs flake.lock`) unless the
     person updated inputs on purpose and wants to keep theirs.
   - A shared file both sides changed: keep both changes where they don't contradict;
     ask when they do.
   - Never take upstream's side for the fork's own `machines/<name>/` or
     `users/<name>/` folders.
5. Leave `machines/eclipse/`, `machines/legion/` and `users/warpledge/` in place. They're
   never built on the fork's machine, and deleting them makes every later merge
   conflict.
6. `nix flake check`, then hand back the rebuild (CLAUDE.md rule 1), `nixm boot` if the
   merge bumped glibc, systemd, niri or xwayland-satellite.

## Prepare a pull request

1. Find the commits that belong upstream: `git log --oneline upstream/main..HEAD`. A
   commit that mixes shared files with the fork's own folders or `flake.lock` has to
   be split first; say so and ask.
2. Branch from upstream, not from the fork's main, so none of the fork's own commits
   come along:
   ```bash
   git switch -c pr/<topic> upstream/main
   git cherry-pick <commit>...
   ```
3. Check the branch carries only shared work:
   ```bash
   git diff --stat upstream/main...HEAD
   ```
   No `machines/<name>/` or `users/<name>/` other than the templates, no `flake.lock`,
   no hostname or username of the fork's in `modules/` or `lib/`. A new app has its
   toggle off in `users/_template/settings.nix` and the rest of the `add-app` steps.
4. `nix flake check` on the branch. Its `stranger` check builds a machine on template
   defaults, which is how upstream's machines will see the change.
5. `git switch -` back to the fork's branch.
6. Pushing and opening the PR stay with the person. Hand them:
   ```
   git push -u origin pr/<topic>
   gh pr create --repo Warpledge/nixos-config --base main --head <github-user>:pr/<topic>
   ```
   with a title and body in the repo's Conventional Commits style. Once it's merged
   upstream, the next sync brings it back and `git branch -d pr/<topic>` tidies up.
