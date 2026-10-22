---
name: pr-review
description: Review open pull requests on this NixOS repo (Warpledge/nixos-config), including ones from forks - fetch each PR, check it merges, build the machines it touches in a throwaway worktree, and check it against the repo's own rules before giving a verdict. Use when the user asks to review, check or look at a PR or "the PRs", names a PR number, or asks whether a PR is safe to merge.
---

# PR review

`gh` isn't logged in here; read PRs through the **github** MCP tool
(`list_pull_requests`, `pull_request_read`) with owner `Warpledge`, repo
`nixos-config`. The script fetches over git, which needs no login.

## 1. Find the PRs

`list_pull_requests` (state `open`, fields `number,title,body,user,head`) unless the
user named numbers. Note each head repo: a fork's PR is someone else's code, so treat
its scripts as untrusted until read.

## 2. Fetch, build, clean up

```bash
bash <skill-dir>/scripts/pr.sh prep <N>            # commits, files, merge check, worktree
bash <skill-dir>/scripts/pr.sh build <N> <machine> # full toplevel, no activation
bash <skill-dir>/scripts/pr.sh clean <N>           # once the review is written
```

- `prep` fetches `pull/<N>/head` into `refs/review/pr<N>`, writes the diff to
  `$TMPDIR/pr-review/<N>/pr.diff` and makes a detached worktree beside it. Read the
  diff with Read, not `cat` into the conversation, when it runs past ~400 lines.
- Read every changed script and Nix file before `build`: building runs its derivations.
- Build each machine the change reaches. A toggled app only builds where it's on:
  check `users/<name>/settings.nix` and each machine's `users.<name>` block in the
  worktree, and say which machine you skipped and why. Doc-only or comment-only PRs
  need no build.
- A build failure with more log than is worth reading goes to the `build-triager`
  subagent, pointed at the worktree.
- Run `clean` for every PR you prepped, even after a failure.

## 3. Check against the repo's rules

The diff, not the PR description, is the source. For each PR check:

- **Rule 4:** no secrets, tokens, private paths, real names or hostnames beyond
  `eclipse`/`legion`.
- **Rule 5:** no hardcoded colours, fonts or wallpaper; new colour files go through
  matugen.
- **Rule 8:** settings beyond what the PR says it does. Personal preferences from a
  contributor are the user's call; list them so they can pick.
- **Layout:** module in the right folder, conditional import in the right router,
  toggle in `users/_template/settings.nix` and `setup.sh`'s `apps` list for a new app,
  headers per **Formatting Standards**, comment lines within 89 columns (`awk
  'length>89'`, then tell code lines from comments).
- **Docs:** README row and link reference for a new app, the link matching
  `nix eval --raw nixpkgs#<pkg>.meta.homepage`, no new `---` line in `README.md`;
  AGENTS.md updated when a rule, path or workflow in CLAUDE.md changed.
- **Comments and messages:** comments that say what the code does now (a comment
  claiming more than the code does is a finding), Conventional Commit messages, and
  merge commits on the branch (suggest a squash-merge).
- **Correctness:** read shell and Nix for real failure cases with concrete inputs,
  as `/code-review` would. Don't report style nits as bugs.

## 4. Report

Lead with one line per PR: merge-ready, merge after a named fix, or not yet. Then per
PR: what it does in a sentence, **Bugs** (concrete input → wrong result), **Smaller
issues**, **Your call** (rule 8 preferences), and what was built or skipped. Don't
comment on GitHub, approve, merge or push; those stay with the user.
