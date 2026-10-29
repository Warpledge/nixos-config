# AGENTS.md

Rules for local models working in this repo (opencode, and Zed's agent, which reads
this file too). Claude Code reads `CLAUDE.md`; this file is the condensed version
of it for a smaller model, kept in sync with it. Everything you need for most tasks
is here. For the rest, `grep -n` CLAUDE.md for the section; don't read it whole.

NixOS flake by warpledge for their machines **eclipse** (desktop) and **legion**
(laptop), and for anyone else who installs it with `setup.sh`. Nixpkgs unstable,
home-manager, Niri WM, Dux Shell (formerly DankMaterialShell, still called DMS in
the code), colours from DMS's matugen (default Catppuccin Mocha), fonts and cursor
from Stylix.

## Whose computer

Before anything touching a machine, a person or their apps:

1. Run `hostname` and `whoami`. The machine is the folder whose `settings.nix` sets
   `hostName = "<hostname>"`, else `machines/<hostname>/`; the person is
   `users/<whoami>/`.
2. Read `machines/<machine>/CLAUDE.md` and `users/<whoami>/CLAUDE.md`: that
   computer's hardware and that person's setup.
3. No machine folder: the person runs `./setup.sh`. No user folder: `./setup.sh
   add-user`. A folder without a `CLAUDE.md`: load the `onboard` skill.

Unless it's `eclipse` or `legion` as `warpledge`, use only that person's files. Never
apply `machines/eclipse/`, `machines/legion/`, `users/warpledge/` or `docs/personal/`
to their hardware or apps.

## Applied Learning

When something fails repeatedly, when the user has to re-explain, or when a workaround is found for a platform/tool limitation, add a one-line bullet here. Keep each bullet under 15 words. No explanations. Only add things that will save time in future sessions.

## Rules

Numbered as in CLAUDE.md, so a skill's "CLAUDE.md rule N" is rule N here.

1. **Never run `nixm rebuild`, `nixm boot` or `nixos-rebuild`.** Hand back: the user
   rebuilds from Omni Settings, or with this when they want you to see the errors:
   `! nixm rebuild 2>&1 | grep -E "error|Error|failed|Failed" || echo "✓"`.
   After any `.nix` edit, run `alejandra <file>` on that file (no hook does it for
   you; never `alejandra .`), then `nix flake check 2>&1 | tail -n 30`. A JSON,
   Markdown or comment-only edit needs neither.
2. **`git add <path>` new files before `nix flake check`**: the flake can't see
   untracked files. Stage by path, never `git add -A` or `git add .`.
3. **Edit in place.** Never rewrite a whole file unless asked. Never delete what
   the task didn't ask you to remove, including comments, commented-out code and
   disabled options. Changing code under a comment? Update the comment, keep it.
4. **Public repo.** No passwords, API keys, tokens or secrets.
5. **DMS's matugen owns colours; Stylix owns fonts and cursor.** Never set colours,
   fonts, font sizes, theme presets or wallpaper in a module, including an app's
   own settings (`theme = "purple"`, `fontWeight`). An app's colours come from a
   matugen template: an entry under `matugen.templates` (option in
   `modules/theme/matugen.nix`; the entry sits there or in the app's module), with
   the template in `modules/theme/matugen/` or beside the module. The app's config
   includes the rendered file, which must stay a plain file, never a home-manager
   link. Fonts come from
   `config.stylix.fonts`. Name a CSS template `.css.matugen`: its `{{ }}`
   placeholders run Zed's biome out of memory.
6. **Commits** use Conventional Commits, `type(scope): subject` plus a bullet body;
   load the `commit` skill. Commit without asking; never push, amend or rebase.
   Commits are authored by the person at the keyboard (their own git identity);
   never pass `--author` or `-c user.name`.
   **Commit once, when the task is finished and checked**, not after each edit,
   and don't end a task that changed files without committing. Run every step
   of the `commit` skill, `scan.sh` included.
   Changed `machines/*/settings.nix` and `users/*/settings.nix` ride along in the
   commit being made, unmentioned in its message (or a `chore(<machine>): save
   settings from Omni Settings` one alone when nothing else changed); never leave
   them uncommitted.
   A feature and every fix, tweak and doc change made for it while you're still
   working are one commit. Split only unrelated changes. Since you can't amend, an
   early commit can't be folded in later.
7. **Screenshots need consent.** When a capture of the screen or a window would help
   the task, ask with a question prompt that says why and that a yes lasts the
   rest of the session. After a yes, don't ask again; never capture without one
   or for anything else.
8. **Set only what was asked for.** No extra options, and never restate an app's
   defaults: set only the values that differ, after checking what the default is.
   Additions worth having go at the end as optional suggestions; add only what the
   user picks.
9. **Ask before writing new docs** (a new `.md`, a new doc section, a comment over
   two lines) with a question prompt saying what it covers and where it goes;
   the user allows or declines. Always propose docs for critical
   infrastructure someone needs to understand to change it safely. Keeping
   existing docs accurate needs no approval.
10. **No memory files.** If something is worth remembering, propose the line for
    CLAUDE.md or this file and let the user decide.
11. **`rm` takes literal absolute paths**, one deletion per command, never `$VAR`.
12. **Do not make any changes until you have 95% confidence in what you need to build.** Ask me follow-up questions until you reach that confidence.

## Starting a task

Any task with more than two steps, a read-only audit included, starts with a todo
list made with the `todowrite` tool (or a file in `/tmp` without it), one item per
step, not per file. Tick items off as you go; after a compaction, it's where you
pick up. Read the files a step needs together, several `read` calls in one turn.

## Finishing a task

A task that changed files isn't done until all four steps are. Put them on your
todo list at the start, and don't write your summary before step 3.

1. `alejandra <file>` on each `.nix` file you changed.
2. `nix flake check 2>&1 | tail -n 30` (skip for JSON, Markdown or comment-only
   changes). Its `stranger` check builds a machine on template defaults, so a
   shared module that needs `machines/` or `users/warpledge/` fails there.
3. Load the `commit` skill and run every step, `scan.sh` included.
4. Reply with what changed and the commit hash.

## Verify, don't guess

Most mistakes so far were confident guesses that still passed `nix flake check`
and then did nothing, or the wrong thing. Evaluation passing proves very little:
unknown keys in `nixpkgs.config`, an app's JSON settings or a plugin's settings are
accepted silently.

- **Before setting an option, read where it's defined.** For a flake input's
  module, find it in the source:
  `nix eval --raw --impure --expr '(builtins.getFlake "/etc/nixos-config").inputs.<name>.outPath'`
  then `grep -rn mkOption` there and read how the option is used (a `settings`
  option often writes a read-only store link, not a file the app can save to).
  For nixpkgs and home-manager options, use the `nixos` MCP tool.
- **Check an app's setting names, defaults and units in its source** before
  writing them (a QML `property`, a settings schema, the man page). An interval
  in minutes is not seconds.
- **Check a package attribute exists**: `nix eval --raw nixpkgs#<attr>.name`.
- **Never write a homepage, description or option name from memory.**
  `nix eval --raw nixpkgs#<pkg>.meta.homepage`.
- **Don't blame upstream in a comment** ("nixpkgs bug") unless you read the
  upstream code and it shows the bug.
- **Think through what the change does at runtime**, not only whether it builds:
  spawning a terminal app (yazi, btop) without a terminal opens nothing; a file in a
  shared module reaches every machine.
- **Never say a fix "should work".** Report the command you ran and its result.

## Stop looping

You have got stuck repeating the same step until the user stopped you. Follow
this, in thinking and in tool calls alike:

- **Before retrying, name what's different.** If you can't say what changed since
  the last attempt (a new file read, a new hypothesis, a different command),
  don't run it again.
- **Two strikes per approach.** If the same fix or command fails twice, drop that
  approach. After three different approaches fail, **stop and report**: what you
  tried, the exact errors, and your best guess at the cause. Then wait.
- **Don't re-read a file or re-run a command to "check again"** when nothing has
  changed since. The output will be the same.
- **Nix reports one error at a time.** A new error after a fix is progress, not a
  repeat; the same error at the same line means the fix didn't apply.
- **In thinking: when you notice you're restating a plan you already made, act on
  it or ask.** Don't weigh the same options again.
- **Unsure what the user wants? Ask** instead of guessing and iterating.
- **When a check contradicts what the user described** (they report an error and
  `nix flake check` passes), say so after that first check and ask. Don't hunt
  through branches, builds and other tools for it.
- **Don't build when `nix flake check` answers the question.** If you must
  build, always pass `--no-link`, or a `result` link is left in the repo.
- **`nix flake check` evaluates every machine in `machines/`.** A pass means none
  has an evaluation error, so never build another machine's system to look for
  one; that compiles a whole second system.

## Context budget

128K tokens, about 10K of it taken by tool definitions in opencode (27K before
it turned the GitHub MCP off on 2026-10-23; that server's schemas were ~17.7K). Long tasks get compacted and whatever only
lived in context is lost.

- **After a compaction**, read the todo list (see **Starting a task**) and run
  `git status --short && git diff --stat && git log --oneline -3`. Re-read only
  what you'll quote.
- **After a compaction, the summary is not a source.** Before quoting a value, a
  default or a `file:line` in your answer, re-read that line (`grep -n`) and quote
  what the file says. A file the summary names may not exist: check it.
- **Never read a large file whole.** `README.md` and `CLAUDE.md` (~40 KB each):
  `grep -n` the lines, then read that range with offset and limit. Same for any
  file over ~300 lines.
- **Read each file once**, and only what the task touches. Two or three sibling
  modules are enough to learn a pattern.
- **Trim output at the source**: `| tail -n 30`, `| grep`. Never print a store
  listing, a derivation or a full build log.
- **Small edits**: the shortest unique `oldString`. Finish one file before the next.
- **Batch** independent shell commands into one call, and independent file reads
  into one turn.
- When asked "where are we?", give a short status (done, blocked, next) and wait.

## Where things go

`flake.nix` → `lib/settings.nix` (reads the settings files) →
`machines/<name>/default.nix` → `modules/default.nix` → `modules/{nixos,home}/`
and the active WM's `modules/wm/<wm>/`.

| Change | Path |
| --- | --- |
| Shared system config | `modules/nixos/` |
| Shared user config | `modules/home/` |
| A user app toggle | `users/_template/settings.nix` (off), then `users/<name>/settings.nix` |
| A machine toggle (service, kernel, WM) | `machines/_template/settings.nix` (off), then `machines/<name>/settings.nix` |
| One user's change on one machine | `users.<name>` block in `machines/<machine>/settings.nix` |
| Monitors, bars, GPU env for one machine | `machines/<name>/wm/<wm>.nix`, never a shared module |
| WM behaviour for everyone | `modules/wm/<wm>/home/` |
| Something only one machine will want | `machines/<name>/`, never `modules/` |
| Something only one person will want | `users/<name>/home.nix` (a home-manager module) |

- `modules/` is shared by everyone who installs the repo. One computer's hardware:
  the machine's `default.nix` or a file beside it, home-manager modules through
  `home-manager.users.<name>.imports` there. One person's own setup on every machine:
  `users/<name>/home.nix`, imported when it exists. A feature anyone could turn on:
  `modules/` behind a toggle off in the template, committed apart from the person's
  own folders. Ask when unsure.
- **Forks**: other people run the repo from a fork of `Warpledge/nixos-config`. The
  `upstream` skill merges upstream's changes in and prepares pull requests back. Keep
  warpledge's folders in a fork untouched; the person pushes and opens the PR.

- Modules are loaded by `lib.optionals user.<cat>.<app> [./path.nix]` in a router
  (`modules/home/programs/default.nix`; `gaming.*` in `programs/gaming/default.nix`).
  Don't also wrap the new module's body in `lib.mkIf`.
- NixOS modules get `machine` and `anyUser`; home modules get `machine` and `user`.
  Every setting exists after `lib/settings.nix`, so read `user.media.mpv`, no
  `or false`.
- Settings files stay plain data: no `let`, functions or interpolation.
- Several folders have their own `CLAUDE.md`, which isn't loaded for you. Their
  hard rules are condensed under **Folder rules** below.

## Gotchas

- **A GUI app's settings must stay writable.** `home.file`/`xdg.configFile` and
  most upstream `settings` options make read-only store links, so the app can't
  save. Use `lib/mutable-merge.jq` through an activation script, as
  `modules/home/programs/file-browsers/dux-files.nix` and `editors/zed.nix` do.
- `boot.kernelModules` silently swallows kernel parameters; they go in
  `boot.kernelParams`.
- A package an update broke: the `disable-package` skill. Remove it from the
  package list; nixpkgs has no setting that disables a package.
- Don't add `inputs.nixpkgs.follows` to `alejandra`, `claude-code`,
  `affinity-nix` or `cachyos-kernel`.
- **After renaming or removing something, `grep -rn` the old name** across the
  repo (`--exclude=flake.lock`) and fix every hit, docs and README included.
  Deleting a doc means removing its entry in `docs/CLAUDE.md` too.

## Folder rules

Condensed from each folder's `CLAUDE.md`. Before a change that goes past these
lines, `grep -n` that file for the part you need.

**`modules/wm/`** (also `machines/*/wm/` and `modules/home/variables.nix`)

- Niri is the only WM; Hyprland's config is on the `hyprland-backup` branch.
- Binds go in `niri.keybinds.<id>` (`key`, `title`, `action`, `group`), not
  `programs.niri.settings.binds`; `core/keybinds.nix` converts them, applies
  each user's `keybinds` setting, and fails the build on two binds sharing a key.
- Shared window rules are in `core/window-rules.json`, each with an `id`; each
  user's `windowRules` setting turns one off, replaces it or adds `custom-` ones.
- **Niri spawns with arguments are lists** (`spawn = ["dms" "ipc" "call" ...]`);
  a spaced string fails the build.
- DMS `settings.json` in `<wm>/home/dms/` is shared by every machine and written
  as a real file the GUI saves to (`dms.mutableFiles`). Machine bars go in the
  machine's `wm/niri.nix` through `dms.extraSettings`. Plugin settings go in
  `dms.pluginSettings.<plugin>`, not `plugins.<plugin>.settings`.
- `settings.json` mirrors what the user set in the DMS settings window.
- Keep `QT_QPA_PLATFORM`, `GDK_BACKEND`, `SDL_VIDEODRIVER` X11 fallbacks
  (`wayland;xcb`, `wayland,x11`, `wayland,x11`). DMS launches apps with the
  systemd user environment (`variables.nix`), not niri's `environment` block.
- Don't touch the XDG portal setup (`niri/session.nix`, `core/portals.nix`)
  without reading `docs/wm/niri-xdg-portals.md`.

**`modules/nixos/`**

- A module that opens a port: list it in `modules/nixos/CLAUDE.md`'s Network
  section. Local services (FlareSolverr, Suwayomi, Open WebUI) listen on
  127.0.0.1 only.
- Mullvad settings are applied through the `mullvad` CLI from a oneshot unit,
  never by templating its `settings.json`.
- Audit tooling is `lynis` and `sbomnix`/`vulnxscan`. **Never `vulnix`**: its NVD
  feeds are retired.
- AppArmor profiles (`security/apparmor/`, one module per app) stay in
  `complain` mode, attach by store-path glob (`/nix/store/*-mpv-*/bin/mpv`), never
  to a binary Nix builds also run (unzip, tar). Run `apparmor-check` after.
- `services/ssh.nix` owns sshd and fail2ban; key-only auth, and an assertion
  fails the build if no user lists a key.
- A NixOS module that configures every user's home writes
  `home-manager.users = lib.mapAttrs (_: _: {...}) machine.users;`, never
  `home-manager.sharedModules` (it reorders list options).
- A new unconditional overlay goes in `nix/nixpkgs.nix`. `allowBroken` is on, so
  only a build shows a broken package.

**`modules/home/`**

- Home routers take `user` as a plain first argument
  (`user: {lib, ...}: {...}`, imported with `(import ./gaming user)`). Don't
  switch them to `lib.modules.importApply`: it reorders the home modules.
- Keep the `clearStaleBackups` activation hook in `default.nix`; on a "file
  exists" error, find the real conflicting file.

**`lib/`**

- `settings.nix` fills every setting missing from a settings file with the
  template's value (true/false turned off) and stops eval on a bad one.
- Default apps are chosen in `default-apps.nix` (`mimeapps.list` is forced),
  local models in `local-models.nix`.

**`modules/home/programs/system/omni-settings/`** (a QML app, DMS panel and
window, over a Python backend; full notes split across its `CLAUDE.md`,
`qml/CLAUDE.md` and `src/CLAUDE.md`)

- It builds its pages from the `_template/settings.nix` layout (`#--` sections,
  `#---` headers, trailing comments), so keep that layout when adding a setting.
  Row text is `src/descriptions.json`; hidden settings and page layout are in
  `src/schema.py`.
- `userPackages` is a set of named lists (`{Media = ["vlc"];}`). A setting
  like that must be listed in both `GROUPED` (`src/schema.py`) and `grouped`
  (`lib/settings.nix`), or it's read as nested settings. `keybinds` (the
  Keybinds page's changes by bind id) is in `GROUPED` too, with its own checks:
  `keybindProblems` in `lib/settings.nix` and `keybinds_ok` in `src/helper.py`.
  So is `windowRules` (the Window Rules page's changes by rule id, applied over
  `wm/niri/home/core/window-rules.json` by `window-rules.nix`), checked by
  `windowRuleProblems` and `window_rules_ok`.
- **The app never writes `modules/`** or the `_template` files: every setting
  goes in a machine's or user's `settings.nix` (`backend.save` refuses other
  paths). Shared data a page changes stays read-only in `modules/`, with the
  changes taken as a user setting, as `keybinds` and `windowRules` do.
- `userPackages` is only for what the user installs from Search. An app the
  config ships gets a toggle and module under Default Packages (`add-app`),
  never a `userPackages` entry.
- **Security:** its root helper (`nixos/system/user/omni-settings-helper.nix`,
  `src/helper.py`) must only accept typed values for the caller's own
  `users/_template` keys, never file text or Nix. Admin-only requests check
  wheel first. Don't loosen either.
- Passwords reach the helper on stdin, never as an argument.
- The front end is `qml/` (the window, `omni-settings`) and `plugin/` (DMS's
  panel, Mod+S); data comes from `src/api.py`, jobs from the
  `omni-settings-jobs` service. Never name a QML property `on`
  plus a capital (it's read as a handler) or after an `Item` property
  (`data`, `state`), and give tap handlers
  `gesturePolicy: TapHandler.ReleaseWithinBounds`. JSON sent back from QML
  loses `.0` and can have its keys sorted, so write files from data the
  backend read; a `Repeater` delegate's `modelData` is a copy, so edit the
  source list by index.

**`modules/home/programs/media/freetube/`**

- Settings and blocklist are mirrored into FreeTube's database only when the
  declared content changes, and FreeTube overwrites it on exit: **FreeTube must
  be closed before a rebuild.** Use the `freetube-sync` skill to change either.
- Subscriptions, playlists and history stay out of the repo (personal data).

**`modules/home/programs/ai/`**

- `.claude/settings.json` is the only tracked file under `.claude/`; nothing
  secret goes in it. Its Bash allow rules stay read-only.
- MCP API keys are read at launch from `~/.nixos-config-mcp/`, never written into
  the repo or the store.
- In opencode the GitHub MCP is off (its tool list fills too much context); Zed's
  agent still has it. Without it, for upstream releases, issues and files use `gh`
  read-only: `gh release list -R
  <owner>/<repo>`, `gh api repos/<owner>/<repo>/contents/<path>`.

**`docs/`**

- `docs/CLAUDE.md` indexes every note; adding, renaming or deleting a note
  updates its entry there.
- Update a Minecraft pack's notes when its config or mods change, add a
  `docs/personal/local/local-binary-installs.md` entry per new `~/.local/opt` app, and a
  `docs/nixpkgs/disabled-packages.md` row per package an update forces off.
- In `docs/`: absolute dates and versions, and say where a claim came from.

## Skills

Load the matching skill with the `skill` tool **before** starting, and follow its
steps.

| Skill | Use when |
| --- | --- |
| `add-app` | Installing, adding, enabling or packaging any app, launcher or service |
| `commit` | Every commit, once at the end of the task |
| `disable-package` | An update broke one package; switch it off or back on |
| `freetube-sync` | "I blocked more" / "sync freetube" |
| `apparmor-check` | After editing `modules/nixos/security/apparmor/` |
| `game-troubleshooting` | A game crashes, freezes or won't start |
| `vn-setup`, `rpgm-setup` | Upscaling a visual novel or RPG Maker game |
| `moku-bump` | Updating or repairing Moku/Tsunagu |
| `android-debloat-redo` | Tablet debloat after an OTA |
| `pr-review` | Reviewing a pull request, or "the PRs" |
| `onboard` | The machine or user has no `CLAUDE.md`, or a person updates theirs |
| `upstream` | In a fork: sync from upstream, or send a change upstream as a PR |
| `todo` | "Add X to the todo", or work a `docs/todo/` file tracks is done |
| `handoff` | Wrapping up for a fresh session, or "continue" with a note in `.claude/handoffs/` |
| `flake-update` | Only when the user runs `/flake-update`; never on your own |

- `<skill-dir>` is `modules/home/programs/ai/skills/<name>`.
- A step that hands work to a subagent is yours to do: for
  `public-repo-auditor` (only when the user asks), read `git diff --cached` for personal data, private
  paths, hostnames and tokens; for `prose-reviewer`, cut words from what you
  wrote; for `docs-drift-auditor`, grep the docs for the paths and names you
  changed; for `build-triager`, run
  `nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --no-link 2>&1 | tail -n 40`.

## Formatting

Every module opens with a banner; copy it byte for byte from a neighbour:

```nix
#=====================================================================#
# VIDEO TRIMMER
#=====================================================================#
{pkgs, ...}: {
  home.packages = [pkgs.video-trimmer];
}
```

- Sections: `#-- Name` between two `#----...----#` rules; items: `#--- text`.
- Take only the arguments you use; `deadnix --no-lambda-arg <file>` finds the rest.
- Comment only what the code doesn't make obvious; most lines need none.
- Comments are short and say *why*: no narration ("we"), no restating the code,
  no alternatives. Lines within 89 columns: `awk 'length>89' <file>`.
- Comments and user-facing text (Omni Settings descriptions, template comments,
  README) are plain, short and easy to read. Keep NixOS terms (rebuild,
  generation, flake input, garbage collection) and explain them briefly.

## Writing style

For replies, `README.md`, `docs/` and commit messages.

- Lead with the answer. No praise, no exclamation marks, no restating the request.
- Full sentences of varied length. Not "it's not X, it's Y"; no lists padded to
  three; don't rate what you describe.
- Avoid: delve, robust, seamless, leverage, crucial, ensure, comprehensive,
  streamline, utilize, enhance.
- No em dashes in `README.md` or `docs/` prose. Never add a `---` line to
  `README.md`.
- A reply naming packages or upstream projects ends with **Sources** links.

## Keeping this file current

CLAUDE.md is the source. When it changes a rule, a path or a gotcha listed here,
this file changes in the same commit. Don't add anything here that contradicts it.
