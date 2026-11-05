# AGENTS.md

Rules for opencode, Zed's agent and Pi, including the local models they run. Claude
Code reads `CLAUDE.md`; opencode, Zed's agent, Pi and their local models read this
file, which carries the rules and the daily workflow in full. `CLAUDE.md` has the
long-form reference.

Every folder with a `CLAUDE.md` also has an `AGENTS.md` symlink to it. opencode
loads that folder's rules when you read a file there, so the full spec arrives with
the file you are about to change. Edit the `CLAUDE.md`, never the symlink.

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

- Scratch QML check files: don't name them `shell.qml`; the Bash hook blocks it.
- Folder `AGENTS.md` is a symlink to `CLAUDE.md`: edit that, never the link.
- A plugin RPC needs `input` and `events`; V2 fails at load without them.
- The Console API is `console.opencode.ai`; `opencode.ai/api` serves the app.
- Usage divides by each model's monthly limit, not the plan's cap.

## Rules

Numbered as in CLAUDE.md, so a skill's "CLAUDE.md rule N" is rule N here.

1. **Never run `nixm rebuild`, `nixm boot`, `nixos-rebuild` or `./setup.sh`.** Hand
   back the rebuild: the user runs it from Omni Settings, or with
   `! nixm rebuild 2>&1 | grep -E "error|Error|failed|Failed" || echo "✓"` when they
   want you to see the errors. After a `.nix` edit run `alejandra <file>` on that
   file; `alejandra .` only when the task already rewrites many Nix files (a flake
   update or bump). Then `nix flake check 2>&1 | tail -n 30`. JSON, Markdown and
   comment-only edits need neither. A machine build is for when you can't tell
   whether a change breaks evaluation or the build, always with `--no-link`.
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
   link. Fonts come from `config.stylix.fonts`. Name a CSS template `.css.matugen`:
   its `{{ }}` placeholders run Zed's biome out of memory.
6. **Commits** use Conventional Commits, `type(scope): subject` plus a bullet body,
   through the `commit` skill (forked: pass what changed and why), authored by the
   person at the keyboard (`user.git.name`/`user.git.email` in
   `users/<name>/settings.nix`), never `--author` or `-c user.name`, never
   warpledge's identity on someone else's account. Commit one coherent unit of
   work, normally one commit per task or feature: its fixes, tweaks and docs go in
   it. Split only for unrelated changes or a fix that stands alone. Don't commit
   each edit or each file, and don't batch unrelated work into one commit. Since
   you can't amend, commit when the unit is finished and checked, and don't end a
   task with a checked change uncommitted. Run the skill's steps, `scan.sh`
   included. Never push, amend or rebase. Changed
   `machines/*/settings.nix` and `users/*/settings.nix` ride along in the commit
   being made, unmentioned (or a `chore(<machine>): save settings from Omni
   Settings` one alone when nothing else changed); never leave them uncommitted.
7. **Docs follow the change.** Update existing docs, indexes and comments the change
   makes wrong, including a short comment where the code would otherwise be unclear,
   without asking. Ask before a new `.md` file or a new section in an existing doc,
   saying what it covers and where. Always propose docs for critical infrastructure
   someone must understand to change it safely.
8. **Memory:** save a note when the user asks you to remember something, and ask
   before saving one they didn't. Private or sensitive notes go to local memory;
   anything publishable that helps the config goes in CLAUDE.md, a skill or `docs/`.
9. **`rm` takes literal absolute paths**, one deletion per command, never `$VAR`.
10. **Do not make any changes until you have 95% confidence in what you need to build.** Ask me follow-up questions until you reach that confidence. For work across several files or modules, write out the plan and get it approved before editing.

## Starting a task

Any task with more than two steps, a read-only audit included, starts with a todo
list made with the `todowrite` tool (or a file in `/tmp` without it), one item per
step, not per file. Tick items off as you go; after a compaction, it's where you
pick up. Read the files a step needs together, several `read` calls in one turn.
The first read in a folder loads its `AGENTS.md`, so open the file you mean to
change before editing it.

## Finishing a task

A task that changed files isn't done until these are done. Put them on your todo
list at the start, and don't write your summary before step 4.

1. `alejandra <file>` on each `.nix` file you changed.
2. `nix flake check 2>&1 | tail -n 30` (skip for JSON, Markdown or comment-only
   changes). Its `stranger` check builds a machine on template defaults, so a
   shared module that needs `machines/` or `users/warpledge/` fails there.
3. Load the `commit` skill and run every step, `scan.sh` included.
4. A QML, plugin or app change: run it and look. Build its package and start it
   the way the folder's `CLAUDE.md` says. A build proves it packages, not that the
   page renders or the button fires once.
5. Reply with what changed and the commit hash.

## Commands

```bash
nix flake check                    # Evaluate every output, no build
nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --no-link
alejandra <file>                   # One file; `alejandra .` only for a multi-file task
nix fmt .                          # Same formatter; a bare `nix fmt` waits on stdin
nixm lint                          # deadnix --no-lambda-arg + statix check, non-blocking
nix flake update <name>            # Bump one input; all of them are /flake-update
run <pkg> [args]                   # zsh: nix run nixpkgs#<pkg>, nothing installed
nixm                               # fzf menu of every subcommand; alias `n`
```

- `nixm boot` instead of `nixm rebuild` when an update bumps glibc, systemd, niri or
  xwayland-satellite: a live switch froze the desktop (2026-10). `nixm rollback` is
  the user's too.
- `nixm upgrade` is `nixm rebuild --update`; `nixm flake-update` bumps every input.
- Never run `nixm`, `nixos-rebuild` or `./setup.sh` yourself. They need sudo and
  activate the system; hand them back.

## Verify what fails silently

Evaluation passing proves very little: unknown keys in `nixpkgs.config`, an app's
JSON settings or a plugin's settings are accepted silently. Check the facts that
fail silently, and act on a reasonable assumption for the rest.

- **Check the facts that fail silently.** A package attribute
  (`nix eval --raw nixpkgs#<attr>.name`), an option's name, default or scope when
  it's new to you (the `nixos` MCP tool), an app's setting names and units in its
  source, and the file:line that proves an interface before you write against it.
  A value change in an option already used nearby doesn't need a fresh read.
- **Homepages and descriptions come from `nix eval`**, not memory. An option name
  you've used in this repo can be reused.
- **Curl a new endpoint before coding against it**: check the status, the content
  type and the first bytes.
- **Think through runtime behaviour**, not only whether it builds: a shared module
  reaches every machine; a terminal app spawned without a terminal opens nothing.
- **Report the command you ran and its result.** Say "unverified" when you didn't
  run it.
- **Don't blame upstream in a comment** ("nixpkgs bug") unless you read the upstream
  code and it shows the bug.

## Looking things up

| Need | Use |
| --- | --- |
| Package metadata | `nix eval --raw nixpkgs#<pkg>.meta.homepage` |
| nixpkgs packages, NixOS and home-manager options | the `nixos` MCP tool |
| Library, SDK or API docs | `context7` |
| Upstream releases, tags, issues, files | `gh` read-only: `gh release list -R <owner>/<repo>` |
| How an upstream repo works (DMS, niri-flake, stylix, Tsunagu) | `deepwiki` |
| How other public flakes configure something | the `grep` MCP tool (grep.app) |
| An app's own config syntax | `nix-shell -p <pkg> --run 'man <name>'` |
| A plugin's RPC methods, events or config fields | the installed `.d.ts` under `node_modules/@opencode-ai/sdk/` |
| What an endpoint actually returns | `curl -sI <url>`, then `curl -s <url> \| head -c 300` |
| A folder's own rules | the `AGENTS.md` there, which loads when you read in it |

- **Stop once you have the answer.** A package's man page settles its config
  syntax; skip the derivation. Don't guess doc URLs: after two failed fetches, read
  a local source.
- **Dump once, grep after** when you need several parts of one document.

## Troubleshooting

- `infinite recursion` → a circular import, a self-referencing conditional, or a
  router reading `user` from module args in `imports` instead of taking it as its
  first argument.
- A message naming `machines/<name>/settings.nix` or `users/<name>/settings.nix`
  → `lib/settings.nix` rejected that setting; it lists each one it accepts.
- `attribute missing` → a module reads a setting the `_template` files don't define.
- Slow or hung → `df -h`, then `nix build --offline`.
- Rollback is the user's: `nixm rollback`, or a generation from the bootloader.

## Working efficiently

- If a fix fails twice, change approach. After three, stop and report what you
  tried and the exact error, then wait.
- Don't re-run an unchanged command or re-read an unchanged file.
- Read each file once, only what the task touches; two or three sibling modules are
  enough to learn a pattern.
- Trim output at the source: `| tail -n 30`, `| grep`. Never print a store listing,
  a derivation or a full build log.
- After a compaction, read the todo list and run
  `git status --short && git diff --stat && git log --oneline -3`; re-read only
  what you'll quote.
- Batch independent shell commands and file reads; finish one file before starting
  the next.
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
| matugen templates, DMS theme, GTK/Qt, Stylix | `modules/theme/` |
| Something only one machine will want | `machines/<name>/`, never `modules/` |
| Something only one person will want | `users/<name>/home.nix` (a home-manager module) |

- `modules/` is shared by everyone who installs the repo. One computer's hardware
  goes in its folder, home-manager modules through
  `home-manager.users.<name>.imports` there. One person's own setup goes in
  `users/<name>/home.nix`. A feature anyone could turn on goes in `modules/` behind
  a toggle off in the template, committed apart from the person's own folders.
- Both `system.stateVersion` and every user's `home.stateVersion` come from the
  machine's `stateVersion` (`25.11` on eclipse, `26.05` on legion). DO NOT CHANGE
  either.
- Never a hostname or username check in `modules/`: it's shared by everyone who
  installs the repo.
- A system service also needs its import in `modules/nixos/default.nix` and a
  name in `setup.sh`'s `services` list.
- Modules are loaded by `lib.optionals user.<cat>.<app> [./path.nix]` in a router
  (`modules/home/programs/default.nix`; `gaming.*` in `programs/gaming/default.nix`).
  Don't also wrap the new module's body in `lib.mkIf`. NixOS modules get `machine`
  and `anyUser`; home modules get `machine` and `user`. Every setting exists after
  `lib/settings.nix`, so read `user.media.mpv`, no `or false`. Settings files stay
  plain data: no `let`, functions or interpolation.
- **Forks**: other people run the repo from a fork of `Warpledge/nixos-config`. The
  `upstream` skill merges upstream's changes in and prepares pull requests back. Keep
  warpledge's folders in a fork untouched; the person pushes and opens the PR.

## Playbooks

Each one names the files that must change together. A missed step is silent: the
build passes and the setting or page does nothing.

**A new setting**

1. `users/_template/settings.nix` (or `machines/_template/`), default off, with a
   one-line comment.
2. `lib/settings.nix` when it is a choice or a list with known values.
3. The machine's or person's `settings.nix`.
4. Omni Settings: `src/schema.py` (`PAGES`, or `HIDDEN` when it stays on its
   template page), `src/descriptions.json` (`title`, `summary`, `text`),
   `setup.sh`'s `apps`/`services` list, and the README row for a package.
5. `nix flake check`; its `stranger` check proves the template default works alone.

**An Omni Settings page**

1. Read the folder's `CLAUDE.md`, `src/CLAUDE.md` and `qml/CLAUDE.md` first.
2. `src/api.py`: `TABS`, `TOP`, `SECTION_TAB`, `shows`, then the nav entry.
3. `src/schema.py`: `PAGES`, `PAGE_TITLES`, `MOVES`, `PAIRS`, `HIDDEN`.
4. The page `.qml` and its entry in `OmniView.qml`; `NAV_SUBTITLES` and
   `PAGE_INTROS`.
5. `src/descriptions.json` for every row.
6. Build the package and start `bin/omni-settings` without a rebuild, then look.
7. Update `src/CLAUDE.md` in the same commit.

**A plugin or RPC change**

1. Read the SDK's `types.gen.d.ts` for `input`, `output` and `events`; V2 fails
   at load without `input` and `events`.
2. Query `console.opencode.ai`, and `curl` it before wiring the code.
3. Load the plugin in a session, not only `nix build`, then try the button.
4. Update `programs/ai/CLAUDE.md` in the same commit.

**A NixOS module**

1. Read `modules/nixos/CLAUDE.md`.
2. Place it per **Where things go**; hardware stays in `machines/<name>/`.
3. Import it with `lib.optionals machine.<name>.enable [./path.nix]` in the
   router; do not also wrap the body in `lib.mkIf`.
4. `alejandra <file>`, then `nix flake check`.
5. A system service also needs `setup.sh`'s `services` list.

## Gotchas

- **A GUI app's settings must stay writable.** `home.file`/`xdg.configFile` and
  most upstream `settings` options make read-only store links, so the app can't
  save. Use `lib/mutable-merge.jq` through an activation script, as
  `modules/home/programs/file-browsers/dux-files.nix` and `editors/zed.nix` do.
- A package an update broke: the `disable-package` skill. Remove it from the
  package list; nixpkgs has no setting that disables a package.
- Don't add `inputs.nixpkgs.follows` to `claude-code`, `affinity-nix` or
  `cachyos-kernel`.
- **After renaming or removing something, `grep -rn` the old name** across the
  repo (`--exclude=flake.lock`) and fix every hit, docs and README included.
  Deleting a doc means removing its entry in `docs/CLAUDE.md` too.

## Folder rules

Each folder's `CLAUDE.md` is the spec and wins on a conflict. It loads in full as
that folder's `AGENTS.md` when you read a file there; this table says where to look
first.

| About to edit | The folder's rules are in |
| --- | --- |
| Omni Settings page or backend | `modules/home/programs/system/omni-settings/CLAUDE.md`, `src/CLAUDE.md`, `qml/CLAUDE.md` |
| Omni Server, or an Omni Settings QML file it shares | `modules/home/programs/gaming/omni-server/CLAUDE.md` |
| A skill, subagent, MCP entry or opencode setting | `modules/home/programs/ai/CLAUDE.md` |
| A NixOS module | `modules/nixos/CLAUDE.md` |
| A home-manager module | `modules/home/CLAUDE.md` |
| `lib/`: settings, default apps, mutable-merge | `lib/CLAUDE.md` |
| App colours, matugen templates, Stylix | `modules/theme/CLAUDE.md` |
| Niri, DMS, portals, keybinds | `modules/wm/CLAUDE.md` |
| FreeTube settings or blocklist | `modules/home/programs/media/freetube/CLAUDE.md` |
| A note under `docs/` | `docs/CLAUDE.md` |

## Skills

Load the matching skill with the `skill` tool **before** starting, and follow its
steps.

The loaded skill descriptions say when to use each one. Two aren't loaded here:
`handoff`, for wrapping up with a note in `.claude/handoffs/`, and `flake-update`,
only when the user runs `/flake-update`.

- `<skill-dir>` is `modules/home/programs/ai/skills/<name>`.
- `commit`, `freetube-sync` and `apparmor-check` run forked: they can't see this
  chat, so pass what changed and why as the argument, and expect questions back.
- A step that hands work to a subagent is yours to do: for
  `public-repo-auditor` (only when the user asks), read `git diff --cached` for
  personal data, private paths, hostnames and tokens; for `prose-reviewer`, cut
  words from what you wrote; for `docs-drift-auditor`, grep the docs for the paths
  and names you changed; for `build-triager`, run
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
- `nix fmt` with no argument waits on stdin; use `nix fmt .`. `nixm lint` runs
  deadnix plus statix.

## Writing style

For replies, `README.md`, `docs/` and commit messages.

- Lead with the answer. No praise, no exclamation marks, no restating the request.
- Chat replies: number multi-step tasks, bold the one line not to miss, end
  with the single next step. Group lists over five items under headings; cut
  nothing.
- Full sentences of varied length. Not "it's not X, it's Y"; no lists padded to
  three; don't rate what you describe.
- Avoid: delve, robust, seamless, leverage, crucial, ensure, comprehensive,
  streamline, utilize, enhance.
- No em dashes in `README.md` or `docs/` prose. Never add a `---` line to
  `README.md`: Zed's preview pairs them like front-matter. Check with
  `nix run nixpkgs#pulldown-cmark -- < README.md`.
- Date a fact taken from a web page, and say where it came from.
- A reply naming packages or upstream projects ends with **Sources** links.

## Keeping this file current

CLAUDE.md is the source. When it changes a rule, a path or a gotcha listed here,
this file changes in the same commit. Don't add anything here that contradicts it.
A folder's `AGENTS.md` is a symlink to its `CLAUDE.md`: never replace one with a
copy, and never edit the link.
