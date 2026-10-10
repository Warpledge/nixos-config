---
name: commit
description: Commit the current changes in this public NixOS repo as the user, split into logical commits, after a secret and content scan. Run only when the user asks for a commit.
disable-model-invocation: true
---

# Commit

CLAUDE.md rule 6 governs every commit here: the repo's configured git identity (the
user's). Push and history rewrites (amend, rebase, force) stay with the user.

## Steps

1. **See the work**: `git status --short` and `git diff --stat`. Untracked files the flake
   needs are part of it; build artifacts and the Katana runtime files at the root are not.
2. **Group** by what someone would revert as a unit: one commit per separate thing added,
   changed or fixed, not one per file and not everything at once.
   - **Merge**: a feature with its own follow-up fixes and its docs (CLAUDE.md, README,
     `docs/`); several small tweaks in one area made for the same reason (a batch of
     window rules, three related binds); a change and the test or check that came with it.
   - **Separate**: unrelated areas (a Moku fix and a FreeTube sync), and a fix that stands
     alone even if found while doing something else. Changes that cancel out within the
     session (switched to Hyprland, switched back) aren't committed at all.
   - A file mixing topics (`claude.nix`, `settings.nix`, CLAUDE.md) gets split by hunk;
     `git add -p` is interactive and unavailable, so:
     ```bash
     bash <skill-dir>/scripts/hunks.sh list  <file>        # numbered hunks
     bash <skill-dir>/scripts/hunks.sh stage <file> 1,3    # stage just those
     ```
     Two topics inside one hunk can't be split; put that hunk with the larger topic.
   - Propose the grouping to the user (one line per planned commit) before committing
     when there are more than three or four.
3. For each group, `git add <paths>` (or stage hunks), then **check and scan**:
   ```bash
   bash <skill-dir>/scripts/check-staged.sh
   ```
   runs `nix flake check` on exactly the staged tree, via a throwaway commit object, so a
   split commit that references a file staged later fails here instead of landing broken.
   Then:
   ```bash
   bash <skill-dir>/scripts/scan.sh
   ```
   gitleaks runs on the staged changes; any leak or `STOP` line means unstage and ask the
   user. Then have the `public-repo-auditor` subagent review `git diff --cached` for what a
   pattern scanner misses: personal data, private paths and hostnames, adult app or source
   names, tokens in unusual formats. If `.claude/settings.json` is staged, do CLAUDE.md's
   maintenance check on it.
4. **Message** in Conventional Commits form (adopted 2026-10-06; older history is plain
   lowercase summaries, so don't copy its style):

   ```
   type(scope): imperative subject, lowercase, no trailing period, ≤ 72 chars

   - what changed, one bullet per change that matters
   - why, when it isn't obvious from the what (an upstream bug, a broken pin)
   ```

   - **type**: `feat` (new app, module, capability), `fix` (something was broken),
     `refactor` (same behaviour, new shape), `perf`, `docs` (README, `docs/`, CLAUDE.md
     on their own), `chore` (flake input updates, syncs like the FreeTube blocklist),
     `revert`.
   - **scope**: the area as the repo names it: a WM (`hyprland`, `niri`, `dms`), an app
     module (`moku`, `freetube`, `mpv`), a subsystem (`apparmor`, `mullvad`, `kernel`,
     `theme`), `claude` for Claude Code tooling, `desktop`/`laptop` for one host, `flake`
     for input bumps. Omit it when a commit truly spans the whole config.
   - **body**: bullets wrapped at 72 columns; skip it for a one-line change. Docs that
     belong to the change go in the same commit and need no bullet of their own.
   - **breaking**: `type(scope)!:` plus a `BREAKING CHANGE:` footer when a rebuild needs
     more than `nixm rebuild` (a WM switch needing `nixm boot`, a manual migration step).
   - The Writing Style rules apply: no puffery, no "various improvements", no "update
     files". Example: `fix(moku): refresh stale pnpmHash after nixpkgs bump`.
5. Commit with the message from a file so the body keeps its layout
   (`git commit -F <file>`; `-m` per paragraph also works), then
   `git log -1 --format='%an <%ae>%n%B'` to confirm the author is the user.
6. Report the commits made (hash and subject) and that nothing was pushed.

If `nix flake check` hasn't passed on the final state, run it before the first commit;
a commit that breaks evaluation is worse than one big commit.
