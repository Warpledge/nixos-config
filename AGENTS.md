# AGENTS.md

NixOS flake managing two machines, **eclipse** (desktop) and **legion** (laptop), one folder
each in `machines/`, with each person's apps in `users/`. Nixpkgs unstable,
home-manager, Niri WM, Stylix theming (Catppuccin Mocha).

## Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead.
   Run `alejandra <file>` on each Nix file you edited, never `alejandra .`
   (it reformats files the task never touched). Run `nix flake check`, and a host
   build even more rarely, only when you can't tell whether a change breaks
   evaluation or the build (a new module or import, an unfamiliar option, an
   input or package change); a value change in a working option, or a JSON,
   Markdown or comment edit, needs neither. Commit without asking (see
   rule 7); pushing and history rewrites stay with the user.
   `alejandra` only applies to `.nix` files — skip it on Markdown edits.
2. **`git add` new files before `nix flake check`** — the flake ignores
   untracked files and the check fails with "file is not available". Stage
   by path, never `git add -A` or `git add .`, which sweep in unrelated changes.
3. **Stylix owns all theming.** Never set colors, fonts, or wallpaper in a
   module. Enable a program's theming and let Stylix supply the palette.
   catppuccin/nix (`modules/theme/catppuccin.nix`) also auto-enables its
   ports; where both theme an app, one target is switched off in
   `modules/theme/`.
4. **Set only what was asked for.** Do not add extra options, defaults, or
   "nice to have" settings beyond the request.
5. **Surgical edits only.** Never rewrite a whole file. Never delete content
   the task didn't ask you to remove, including commented-out code and
   disabled options.
6. **Public repo.** No passwords, API keys, tokens, or secrets.
7. **Commit format.** Commits you make use the repo's configured git
   identity (the user's). Messages use Conventional Commits: `type(scope): subject`
   (feat, fix, refactor, perf, docs, chore, revert; scope is the repo area,
   e.g. hyprland, moku, flake) plus a bullet body saying what and why.
8. **No desktop screenshots without permission.** Never capture the screen,
   a window, or the desktop unless the user has said yes to that specific
   capture first.
9. **Never say a fix "should work".** Nix reports one error at a time, so
    the line it names is rarely the only problem. After a Nix change: check
    every option path and attribute in the file you touched (see **Looking
    things up**), then run `nix flake check 2>&1 | tail -n 30`, fix, and
    repeat until it passes. Report the check's result, not a prediction.
    The check only evaluates a module where its toggle is on: a toggle that's
    off on every machine passes without testing anything.
10. **Ask before writing new docs or long comments.** A new `.md` file,
    a new section in an existing one, or a new comment longer than a line
    or two needs the user's yes first; propose it in a sentence and wait.
    Keeping existing docs accurate needs no approval. A one-line comment
    where the code would otherwise be unclear is fine.
11. **`rm` takes literal paths.** Write the absolute path, never `$VAR`
    (`rm /run/user/1000/a`, not `rm $XDG_RUNTIME_DIR/a`), and run each
    deletion as its own command, never chained onto a read-only check.

## Context budget

Your context window is 128K tokens and the tool definitions already use about
27K of it. Long tasks get compacted, and whatever you only held in context is
lost. Work so that compaction costs nothing:

- **Start every multi-step task with a todo list** (the `todowrite` tool), one
  item per file or step, and tick items off as you go. After a compaction, read
  the todo list and run `git status --short && git diff --stat` to see where you
  are. Do not re-read files to rebuild your memory.
- **Never read a large file whole.** `CLAUDE.md` (~40 KB) and `README.md`
  (~38 KB) are off limits in full: `grep -n` for the lines you need, then read
  that range with an offset and limit. Do the same for any file over ~300 lines.
- **Read each file once**, and only the files the task touches. Two or three
  sibling modules are enough to learn a pattern.
- **Trim command output at the source**: `nix flake check 2>&1 | tail -n 30`,
  `alejandra <file> 2>&1 | tail -n 5`, man pages through `grep`. Never print a store
  listing, a derivation or a full log.
- **Small edits.** Use the edit tool with the shortest unique `oldString`, not a
  whole-file write. Finish one file before opening the next.
- **Batch** independent shell commands into one call.
- **Don't think in circles.** Once you know the next step, take it.

## Skills

The repo's skills are loaded through the `skill` tool. When a request matches
one, load it **before** doing anything else and follow its steps; they carry
checks that are easy to miss.

| Skill | Use when |
| --- | --- |
| `add-app` | Installing, adding, enabling or packaging any app, launcher or service |
| `commit` | Every commit |
| `disable-package` | An update broke one package; switch it off or back on |
| `freetube-sync` | "I blocked more" / "sync freetube" |
| `apparmor-check` | After editing `modules/nixos/security/apparmor/` |
| `hyprland-verify` | After editing Hyprland config |
| `game-troubleshooting` | A game crashes, freezes or won't start |
| `vn-setup`, `rpgm-setup` | Upscaling a visual novel or RPG Maker game |
| `moku-bump` | Updating or repairing Moku/Tsunagu |
| `android-debloat-redo` | Tablet debloat after an OTA |
| `flake-update` | Only when the user runs `/flake-update`; never on your own |

The skills were written for Claude Code. Read them this way:

- `<skill-dir>` is `modules/home/programs/ai/skills/<name>`, so run
  `bash modules/home/programs/ai/skills/add-app/scripts/check-app.sh ...`.
- "CLAUDE.md rule 1" is rule 1 above (no rebuilds, when to flake check);
  "rule 6" is rule 7 above (commit format). Do not open `CLAUDE.md` to look
  a rule up. If a skill names a CLAUDE.md section you need, `grep -n` it.
- A step that hands work to a subagent (`public-repo-auditor`,
  `prose-reviewer`, `build-triager`, `docs-drift-auditor`) is yours to do:
  for the auditor, read `git diff --cached` for personal data, private paths,
  hostnames and tokens; for the prose pass, cut words from what you wrote.

Several folders carry their own `CLAUDE.md`. Read it first before changing
files in that area:

- `modules/wm/` — DMS keybind syntax, window rules, monitor config, mutables
- `modules/nixos/` — module loading patterns, overlays, stateVersion rules
- `programs/system/nixos-settings/` — template format, schema.py layout, helper flow
- `programs/media/freetube/` — blocklist mirroring rules, what stays out of the repo
- `modules/home/programs/ai/` — skills, agents, MCP servers, subagents
- `docs/` — documentation conventions, todo notes, disabled packages

## Looking things up

**Never write a package homepage, description, or option name from memory.**

| Need | Use |
| --- | --- |
| Package metadata | `nix eval --raw nixpkgs#<pkg>.meta.homepage` |
| nixpkgs / NixOS + home-manager options | the `nixos` MCP tool |
| An app's own config syntax | `nix-shell -p <pkg> --run 'man <name>' \| col -b \| grep -A3 <term>` |
| A home-manager module for a program | `find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix' \| head -1` |

If the home-manager module exists, read it and use `programs.<pkg>` instead
of `home.packages`.

**Available MCP tools:** deepwiki for upstream wiki docs on public repos,
context7 for version-specific library docs and code examples, grep for
real-world code across public GitHub repos.

**Check every option path and attribute name before writing it.** Your memory
of them is often out of date or invented. Look an option up with the `nixos`
MCP tool, or `grep -n 'mkOption' <module>` (some move under a submodule, e.g.
VSCodium's extensions are `profiles.default.extensions`). Check a package
attribute exists with `nix eval --raw nixpkgs#<attr>.name`, extensions too
(`nixpkgs#vscode-extensions.<publisher>.<name>.name`).

Stop once you have the answer: a man page is
authoritative for config syntax, so don't go on to the nixpkgs derivation.
Don't guess documentation URLs; after two failed fetches, use a local source.

## Architecture

`lib/settings.nix` reads `machines/<name>/settings.nix` and the
`users/<name>/settings.nix` of each user it lists, and passes them on: NixOS
modules get `machine` (machine settings, users' final settings in
`machine.users`) and `anyUser` (each user toggle, on if any user has it); home
modules get `machine` and `user`. The two `_template/settings.nix` files list
every setting; anything a file leaves out is off. Home routers read `user` in
`imports`, so they take it as a first argument (`user: {lib, ...}: {...}`,
imported with `(import ./gaming user)`).

| Scope | Path |
| --- | --- |
| Shared user config | `modules/home/` |
| Shared system config | `modules/nixos/` |
| Machine toggles (services, kernel, WM) | `machines/<name>/settings.nix` |
| User toggles (apps) | `users/<name>/settings.nix` |
| One user's change on one machine | `users.<name>` block in `machines/<machine>/settings.nix` |
| Where a new app's import goes | `modules/home/programs/default.nix`; `gaming.*` in `programs/gaming/default.nix`; guitar apps in `audio/guitar/default.nix`, toggle added to that folder's gate in `programs/default.nix` |

### Module layout

- `modules/nixos/` — system: `gaming/` (default, steam, `performance/` esync + gamemode + kernel, `tools/` gamescope + java), `network/` (default, blockers, dns, firewall, networkmanager), `nix/` (default, nh, nixpkgs, substituters), `security/` (auditd, clamav, `apparmor/`, `auth/` keyring + sudo, `hardening/` default + kernel, `mullvad/`), `services/` (desktop, `hardware/` adb + bluetooth + gpu + keyd + power + printing + sound, `runtimes/` docker + flatpak + runners, `servers/` flaresolverr + suwayomi + sunshine + syncthing, ssh), `system/` (bootloader, documentation, packages, `desktop/` input + wayland, `language/` locale + japanese-ime, `tuning/` tweaks + zram, `user/` config-repo + shell + user + nixos-settings-helper)
- `modules/home/` — user: `programs/` (browsers, terminals, editors, ai, shell, fetch, file-browsers, graphics, audio, media, office, security, system, gaming (`launchers/`, `games/`, `tools/`, `scripts/`), git, android, discord, plus `options.nix` and `utilities.nix` at its root). `mime.nix`, `nixm.nix`, `services.nix` and `variables.nix` are single files at that level
- `modules/wm/{hyprland,niri}/` — each has `session.nix` (NixOS: turns the WM on, login screen, keyring unlock) and `home/` (home-manager, everything else, including DankMaterialShell/DMS); `modules/wm/dms-mutable.nix` is the settings merge both DMS modules import, and `modules/wm/dms-polkit/` the patch for the full-screen modal polkit prompt
- `modules/theme/` — stylix, catppuccin, fonts, plus `gtk.nix`, `qt.nix` (toolkit theming), and `dms.nix` (DMS theme built from Stylix's palette)
- `machines/<name>/` — `default.nix`, `settings.nix`, `hardware/` (`gpu.nix`, `hardware-configuration.nix`), `wm/<wm>.nix` (per-WM machine overrides: monitors, GPU env vars, autostart, desktop's DMS bars)

`browsers/zen/`, `media/{freetube,moku}/` and `gaming/launchers/xsystem4/` have a
`default.nix` of their own, but they're module bundles, not routers. The
conditional import (`++ lib.optionals user.media.foo [./media/foo.nix]`) is
what gates a module; do **not** wrap a new module's body in `lib.mkIf` instead.

**A new toggle goes in its template first.** `users/_template/settings.nix`
(`false` unless every new user should get it) or `machines/_template/settings.nix`,
then on in `users/warpledge/settings.nix` or the machine's file, and in
`setup.sh`'s `apps` or `services` list.

### NixOS Settings app

`programs/system/nixos-settings/` is a Python GTK4/libadwaita GUI for managing
the config without editing code or running rebuild commands. It is imported for
every user with no toggle. It builds pages from `_template` files (`#--`
sections, `#---` headers, trailing comments), gets labels from `setup.sh`'s
`apps`/`services` lists, and gets dropdowns from the `choices`/`userChoices`/
`listChoices` that `lib/settings.nix` exports. A new setting appears in the app
automatically once its toggle and template are in place.

Layout is controlled by `src/schema.py`: `HIDDEN` (settings to exclude), `PAGES`
(sidebar sections, icons, blurbs, and which group each setting belongs to),
`PAGE_TITLES`, `MOVES`, and the port lists (`PORT_LISTS`). A setting no page
names stays on its template page. The user manually places settings into tabs
and categories by editing `schema.py`.

Settings files must be plain data (no `let`, functions, or string
interpolation), or the app can't parse them. Each user's copy edits only that
user. Before changing the app, its helper, or the template layout, read
`modules/home/programs/system/nixos-settings/CLAUDE.md`.

### Gotchas

- **`boot.kernelModules` silently swallows kernel parameters.** modprobe cannot
  resolve them, `systemd-modules-load.service` logs `Failed to find module` and
  still exits 0, so the hardening looks applied and is not. An assertion in
  `security/hardening/kernel.nix` now fails the build on any entry containing
  `=`; bare flags like `slab_nomerge` still get through.
- **`gaming.steam` is wired in `modules/nixos/gaming/default.nix`** (on
  `anyUser.gaming.steam`, so Steam is installed system-wide); the rest of
  `gaming.*` is wired in `home/programs/gaming/default.nix`.
- **Module *loading* goes through `lib.optionals` in a `default.nix`; config
  *logic* inside a module uses `if/then/else`.** Mixing them up is why an option
  looks wired but has no effect.
- **Non-admin users** are added to `nix.settings.allowed-users` (otherwise
  `@wheel` only): home-manager's activation runs `nix-env` as each user.
- **Moku is built from source, pinned twice:** the `moku` and `tsunagu` inputs
  move together. The `moku-bump` skill has the bump order.
- **Flatpak apps aren't declarative.** The repo only installs Flatseal via
  `nix-flatpak`; other Flatpaks are installed by hand and managed through
  NixOS Settings' Flatpaks page. Don't try to add Flatpak apps declaratively.
- **Every setting exists once** `lib/settings.nix` has filled the gaps, so read
  it as a bare path (`user.media.mpv`); `or false` isn't needed.
- **Read tool truncates lines over 2000 chars.** Use `grep` or `sed` to read
  specific ranges when dealing with long lines (README tables, single-line
  JSON, etc.).

### Machine context

The flake manages two machines: **eclipse** (desktop, Ryzen 5800X3D + RX 9070 XT, 280Hz OLED + 144Hz) and **legion** (laptop, Legion Slim 5, Ryzen 7735HS + hybrid AMD 680M/RTX 4070, 1600p@165Hz). Always run `hostname` before diagnosing machine-specific issues. Each machine's folder (`machines/<name>/`) holds its `hardware/` (GPU, storage, swapfile), `settings.nix`, and `wm/<wm>.nix` overrides. Machine-specific hardware lives in the machine's folder, never behind a name check in a shared module.

- `machines/eclipse/` also has `hardware/storage.nix` (LUKS game drive unlock from key files on encrypted root) and `hardware/gpu.nix` (DMS GPU widget config)
- `machines/legion/` also has `hardware/swapfile.nix` and `minecraft-servers/` (server definitions, an fzf picker, and JSON that NixOS Settings' Servers tab reads)

### Conditional import patterns

```nix
# Machine service (nixos/default.nix)
++ lib.optionals machine.clamav.enable [./security/clamav.nix]

# User app (a home router)
++ lib.optionals user.browsers.zen [./browsers/zen]

# System side of a user app (a NixOS router)
++ lib.optionals anyUser.media.mpv [./mpv.nix]
```

### Flake inputs

All inputs follow `nixpkgs` unless noted. Pinned versions: **moku v0.14.0**,
**tsunagu v0.5.0**, **alejandra 3.0.0**. Flake=false: `claude-desktop`,
`moku`, `tsunagu`, `retroshelf`. Non-nixpkgs-followers: `alejandra`,
`nix-flatpak`, `claude-code`, `affinity-nix`, `cachyos-kernel`.

**Never add a `---` line to `README.md`.** Zed's preview pairs them like
front-matter and shows the sections between as raw text.

## Todo notes

Planned work lives under `docs/todo/`, one file per task, named after it
(`todo/affinity-setup.md`). **When the user says "add X to the todo", write a
new file there** holding what the task is, why they want it, what the repo
already has toward it, the steps left, and any research already done (links,
versions, gotchas). Update the file rather than starting a second one for the
same task, and delete it once the work is done. These are working notes: no
`README.md` or Components entry.

### Disabled packages

`docs/nixpkgs/disabled-packages.md` lists packages temporarily disabled because
a nixpkgs update broke them, preventing the flake from building. They are
switched off in the flake's `nixpkgs.config.permittedInsecurePackages` or
`home-manager` config so the user can still rebuild. Before enabling a disabled
package, check the current nixpkgs version — the breakage may have been fixed.

### Setup script

`setup.sh` is the public install script for this NixOS configuration. Users run
it after installing a base NixOS system (the single command in `README.md`). It
presents a questionnaire with defaults, then automatically:
1. Clones this repo
2. Generates machine and user settings from the user's answers
3. Rebuilds the flake on their system

It has two lists — `apps` for home-manager packages and `services` for NixOS
modules. When adding a new toggle, update the corresponding list in `setup.sh`.

## Formatting

Every module opens with a banner. **Copy it byte-for-byte from a neighbouring
module in the same directory** — note the trailing `#` closing both rule lines:

```nix
#=====================================================================#
# VIDEO TRIMMER
#=====================================================================#
{pkgs, ...}: {
  home.packages = [pkgs.video-trimmer];
}
```

Only take the arguments you use: a module that sets no packages does not need
`pkgs`.

Comments are short and explain *why*, not *what*. No session narrative, no
restating the code, no listing alternatives that were not chosen.
Keep comment lines within 89 columns (trailing comments too); shorten the
wording or move the comment above the code.

### Header hierarchy

Use this outline for `README.md` and `docs/`:

| Level | Usage |
| --- | --- |
| `#` | Repo title |
| `##` | Major sections (Overview, Installation, Architecture, etc.) |
| `###` | Subsections within major sections |
| `####` | Detailed breakdowns (rarely needed) |

No blank lines between a header and the content immediately following it.
One blank line before and after headers unless a list or code block follows.

## Troubleshooting

- **Infinite recursion during evaluation** — usually a circular import. Check
  that a module doesn't import itself directly or indirectly. Look for
  `import` cycles in `default.nix` files.
- **Module option not found** — the toggle may be on a different machine,
  or the option moved under a submodule. Use the nixos MCP tool to verify
  the exact path.
- **Setting-rejection messages** — when Nix says a value doesn't match
  expected type, check the option definition; the error points to the
  wrong line often. Look at the surrounding options in the module.
- **Desktop entry not appearing** — AppImages may need `APPIMAGE` and
  `APPDIR` env vars set via `makeWrapper`. If the desktop file
  references a binary that doesn't exist, the wrapper may need to
  create directories first.

## Writing style

For replies, `README.md`, `docs/` and commit messages.

- Lead with the answer. No "Great question", no exclamation marks, no closing
  line praising the work, no restating the request first.
- Say it once and directly. Not "it's not X, it's Y".
- Write full sentences of varied length. No fragments for emphasis.
- Don't rate the thing you are describing. "Stylix sets the palette", not
  "Stylix ensures a consistent look across every application".
- Cut a sentence that adds no information, and any list padded to three.
- Pet words to avoid: delve, robust, seamless, leverage, crucial, ensure,
  streamline, elegant, powerful, utilize, showcase, essentially, furthermore,
  pivotal, foster, enhance, cutting-edge.
- Use contractions and plain words.
- No em dashes inside a sentence in `README.md` or `docs/`. A dash separating
  a label from its description in a list is structure and stays.
- In `docs/`, give absolute dates and versions, and cite where a claim came from.
- A reply that names packages or upstream sources ends with a **Sources** list
  linking each one, taken from `meta.homepage` or the flake input's repo.

Code blocks, command output, quotes and table cells are left alone.
