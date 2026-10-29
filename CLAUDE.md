# CLAUDE.md

## Project

NixOS flake by warpledge, for their desktop **eclipse** and laptop **legion**, and for anyone else who installs it with `setup.sh` and gets their own `machines/<name>/` and `users/<name>/`. Nixpkgs unstable; colours from DMS's matugen (default theme Catppuccin Mocha Mauve), fonts and cursor from Stylix. WM: Niri only; Hyprland was removed on 2026-10-21 and its config kept on the `hyprland-backup` branch.

## Who and which machine

Before a task that touches a machine, a person or their apps, find out whose computer this is. It may not be warpledge's.

1. Run `hostname` and `whoami`. The machine is the folder whose `settings.nix` sets `hostName = "<hostname>"` (`grep -l`), else `machines/<hostname>/`; the person is `users/<whoami>/`, listed under `users` in that machine's `settings.nix`.
2. Read `machines/<machine>/CLAUDE.md` and `users/<whoami>/CLAUDE.md`. They hold that computer's hardware and quirks and that person's setup; Claude Code doesn't load them until a file in the folder is read.
3. If something's missing: no machine folder means the computer wasn't set up from this repo, so the person runs `./setup.sh` (sudo, so never you); no user folder means `./setup.sh add-user`; a folder without a `CLAUDE.md` means the `onboard` skill, which detects the hardware, asks the person the rest and writes it.

Unless the machine is `eclipse` or `legion` and the user `warpledge`, the person's own files are the context. Don't carry over anything from `machines/eclipse/`, `machines/legion/`, `users/warpledge/` or `docs/personal/` (warpledge's notes) to their hardware or apps, and don't fall back on it when guessing. "The user" in this file and the skills means whoever is at the keyboard.

## Applied Learning

When something fails repeatedly, the user has to re-explain, or a tool limitation needs a workaround, add a bullet here under 15 words, no explanation.

## Critical Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead. Hand back a rebuild as runnable from Omni Settings, or with `!` when they want you to see the errors: `! nixm rebuild 2>&1 | grep -E "error|Error|failed|Failed" || echo "✓"` (same for `nixm boot`). Run `nix flake check`, and a machine build more rarely, only when you can't tell whether a change breaks evaluation or the build (a new module or import, an unfamiliar option, an input or package change, Nix you aren't sure of); a value change in a working option, or a JSON, Markdown or comment edit, needs neither. Commit without asking (rule 6); pushing and history rewrites stay with the user.
2. **`git add` new files before `nix flake check`** — the flake won't see untracked files.
3. **Edit existing files in place; don't rewrite them whole.** A rewrite drops commented-out code and disabled options without showing it in review.
4. **Public repo:** no passwords, API keys, tokens, or secrets.
5. **DMS's matugen owns colours; Stylix owns fonts and cursor.** Never hardcode colours, fonts or wallpaper in a module. An app's colours come from a matugen template rendered at runtime into a plain file its config includes (never a home-manager store link); `modules/theme/CLAUDE.md` has how. Fonts and cursor come from `config.stylix.fonts`/`config.stylix.cursor`.
6. **Commits go through the `commit` skill** (forked, so pass it what changed and why), authored by whoever is at the keyboard (`git.name`/`git.email` in their `users/<name>/settings.nix`), never warpledge's on someone else's account, never `--author` or `-c user.name`. Conventional Commits, `type(scope): subject` plus a bullet body. A changed `machines/*/settings.nix` or `users/*/settings.nix` rides along in the commit being made, unmentioned, or gets its own `chore(<machine>): save settings from Omni Settings`: Omni Settings' writes never sit uncommitted.
7. **Screenshots need consent.** When capturing the screen or a window (screenshot tools, `grim`, niri's actions, computer use) would help, ask with AskUserQuestion, saying why and that a yes lasts the session. After a yes, capture for the task without asking again; never without one or for anything else.
8. **Set only what was asked for.** No options, defaults or "nice to have" settings on your own. Offer worthwhile additions after the requested change as an optional multi-select AskUserQuestion and add only what they pick.
9. **Ask before writing new docs or long comments.** A new `.md` file, a new section or note, or a comment over a line or two needs a yes first: propose it with AskUserQuestion saying what it covers and where. Always propose docs for critical infrastructure someone must understand to change it safely. Keeping existing docs accurate needs no approval (CLAUDE.md, AGENTS.md, README rows and links, entries a skill keeps current), nor does a one-line comment where code would otherwise be unclear.
10. **Ask before saving a memory, and offer where it goes.** Local memory (`~/.claude/projects/.../memory/`) is for private or sensitive notes (real names behind stand-ins, personal data, playthrough notes); anything safe to publish that helps the config belongs in the repo (CLAUDE.md, a skill, `docs/`). Let the user pick before writing.
11. **`rm` takes literal paths.** Write the absolute path, never `$VAR` (`rm /run/user/1000/a`, not `rm $XDG_RUNTIME_DIR/a`), and run each deletion as its own command, never chained onto a read-only check or hidden in a script.
12. **Do not make any changes until you have 95% confidence in what you need to build.** Ask me follow-up questions until you reach that confidence. For work across several files or modules, enter plan mode first and get the plan approved.

`AGENTS.md` is the local AI's standalone, condensed copy of this file (same rule numbers, plus guidance for a smaller model). When a rule, path, workflow or gotcha changes here or in a folder's `CLAUDE.md` (condensed under its **Folder rules**), update it in the same commit; the two never contradict.

Only `.claude/settings.json` is tracked; before committing a change to it, and in any CLAUDE.md audit, do the **maintenance check** in `modules/home/programs/ai/CLAUDE.md`. The post-edit hook (alejandra plus repo checks) runs on `Write|Edit` only, so edit tracked files with Edit or Write, not `sed` or a heredoc.

Several folders carry their own `CLAUDE.md` (`lib/`, `modules/nixos/`, `modules/home/`, `modules/wm/`, `modules/theme/`, `docs/`, `modules/home/programs/ai/`, `programs/system/omni-settings/`, `programs/media/freetube/`). Claude Code loads one when it reads a file in that folder; the pointers below say when to read one first.

## Commands

```bash
nix flake check         # Evaluate all outputs, no build (rule 1 says when); its `stranger` check is a machine on template defaults, so shared modules must work without machines/ or users/warpledge/
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel --no-link  # Full build, no activation: catches hash and patch failures that flake check (eval only) misses
alejandra .             # Format all Nix files (v3.0.0); a bare `nix fmt` waits on stdin, use `nix fmt .`
nixm lint               # deadnix --no-lambda-arg + statix check
nixm rebuild            # Apply config (wraps `nh os switch`); user-only, rule 1
nixm boot               # Activate on next boot; use when an update bumps glibc/systemd/niri/xwayland-satellite (live switches froze the desktop, 2026-10)
nix flake update <name> # Bump a single input
run <pkg> [args]        # Ad-hoc launch a nixpkgs package without installing it (zsh function)
nixm <bogus>            # List every nixm subcommand (fzf menu in modules/home/nixm.nix, alias n)
```

## Architecture

```
flake.nix                                  (one system per folder in machines/, except _template)
  → lib/settings.nix                         (reads, fills in and checks the settings files)
    → machines/<name>/settings.nix           (machine toggles + who logs in)
    → users/<user>/settings.nix              (each user's apps; the machine's overrides on top)
  → machines/<name>/default.nix              (machine entry)
    → modules/default.nix                    (NixOS + one home-manager config per user)
      → modules/{nixos,home}/                (modular configs)
      → modules/wm/${windowManager}/         (active WM only)
```

### Machine and user settings

`machines/<name>/settings.nix` (one per computer) and `users/<name>/settings.nix` (one per person) are read by `lib/settings.nix`; the `_template/` copies list every setting and its default, and a left-out true/false is off. NixOS modules get `machine` and `anyUser`, home modules `machine` and `user`. What a machine or user has on is read from these files, never assumed; a machine's `users.<name>` block overrides the person's file there. How gaps are filled, the module arguments and settings like `flakePath`, `defaultApps` and `localAi` are in `lib/CLAUDE.md`.

Omni Settings (`programs/system/omni-settings/`) is a QML app (DMS panel on Mod+S) with a Python backend over these files; read its `CLAUDE.md` before changing the app, its root helper (`nixos/system/user/omni-settings-helper.nix`) or how the templates are laid out (`#--` sections, `#---` headers, trailing comments). Keep the settings files plain data (no `let`, functions or string interpolation), or the app can't parse them.

Gotchas that bite from anywhere; the ones for one tree are in `modules/nixos/CLAUDE.md` and `modules/home/CLAUDE.md`. Grep the option name before assuming which file owns it:

- `boot.kernelModules` silently swallows kernel parameters; they go in `boot.kernelParams` (`modules/nixos/CLAUDE.md`).
- `alejandra`, `claude-code`, `affinity-nix` and `cachyos-kernel` keep their own nixpkgs on purpose (`flake.nix` says why), `nix-flatpak` has no nixpkgs input, and `claude-desktop` is source only. Don't add `inputs.nixpkgs.follows` to them.
- Module *loading* goes through `lib.optionals` in a `default.nix`; config *logic* inside a module uses `if/then/else`. Mixing them up is why an option looks wired but has no effect.
- Every setting exists once `lib/settings.nix` has filled the gaps, so read it as a bare path (`user.media.mpv`); `or false` isn't needed.
- Machine-specific hardware lives in the machine's folder, never behind a name check in a shared module: niri monitors and the desktop's DMS bars in `machines/<name>/wm/niri.nix` (the bars through the `dms.extraSettings` option declared in `niri/home/dms/default.nix`), the desktop's DMS GPU widget in `machines/eclipse/hardware/gpu.nix`.

Import patterns:
```nix
++ lib.optionals machine.clamav.enable [./security/clamav.nix]  # machine service (nixos/default.nix)
++ lib.optionals user.media.mpv [./media/mpv.nix]               # user app (a home router)
++ lib.optionals anyUser.media.mpv [./mpv.nix]                  # system side of a user app
./wm/${machine.windowManager}/session.nix  # + ./wm/<wm>/home per user (modules/default.nix)
++ (lib.optional (machine.windowManager == "niri") ./wm/niri.nix) # machines/<name>/default.nix
```

`nixpkgs.config`, the overlays, `allowBroken` and `permittedInsecurePackages` are covered in `modules/nixos/CLAUDE.md`. Both `system.stateVersion` and every user's `home.stateVersion` come from the machine's `stateVersion` (`25.11` on the desktop, `26.05` on the laptop since its reinstall), marked DO NOT CHANGE.

### Module layout

`ls` a folder for its files; this lists what a listing won't tell you.

- `modules/nixos/` — system: `gaming/`, `network/`, `nix/`, `security/`, `services/` (`hardware/`, `runtimes/`, `servers/`), `system/`
- `modules/home/` — user: `programs/<category>/` plus a few root files; its `CLAUDE.md` has the layout, the `~/.local/opt` and AppImage wrappers, and `clearStaleBackups`. Skills and subagents live in `programs/ai/{skills,agents}/`, registered in `claude.nix`
- `modules/wm/niri/` — `session.nix` (NixOS: turns the WM on, login screen, keyring unlock) and `home/` (home-manager, everything else, including DankMaterialShell (DMS)); `modules/wm/dms-mutable.nix` is the settings merge its DMS module imports, and `modules/wm/dms-polkit/` the polkit dialog patch it imports (`modules/nixos/CLAUDE.md`)
- `modules/theme/` — matugen templates, the default DMS theme, GTK/Qt and Stylix; its `CLAUDE.md` says what each file does
- `lib/` — the settings reader, default apps, local models and `mutable-merge.jq` (keeps GUI changes across rebuilds); its `CLAUDE.md` has the details
- `machines/<name>/` — `default.nix` (machine entry), `settings.nix`, `hardware/` (`gpu.nix`, `hardware-configuration.nix`), `wm/<wm>.nix` (per-WM machine overrides for every user: monitors, GPU env vars, autostart, the desktop's DMS bars)
- `machines/_template/` and `users/_template/` — what `setup.sh` copies (no `CLAUDE.md`; the template `hardware-configuration.nix` throws until replaced)
- `users/<name>/` — `settings.nix` (account and apps) and an optional `home.nix` (their own home-manager config)
- `setup.sh` — new computer or reinstall from the templates, plus `add-user`, `build` and `share` (moves the clone to `/etc/nixos-config`); asks before sudo

### Where to place things
| Scope | Path |
| --- | --- |
| Machine toggle (services, kernel, WM, locale) | `machines/<name>/settings.nix`, listed in `machines/_template/settings.nix` |
| User toggle (apps, account) | `users/<name>/settings.nix`, listed in `users/_template/settings.nix` |
| One user's change on one machine | the `users.<name>` block of `machines/<machine>/settings.nix` |
| Per-machine WM overrides (monitors, GPU env vars) | `machines/<name>/wm/niri.nix` |
| Shared system / user / WM | `modules/nixos/`, `modules/home/`, `modules/wm/niri/` |

### Whose change is it

`modules/` is shared by everyone who installs the repo, so it only takes what others could use too. Ask when it isn't obvious which side a change falls on.

- **One computer's hardware** (a device, a workaround for a monitor, a game installed on one drive): the machine's folder. NixOS options go in `machines/<name>/default.nix` or a file beside it, and home-manager modules in `home-manager.users.<name>.imports` there, as `machines/eclipse/default.nix` imports its games.
- **One person's own setup, on every machine they use** (their scripts, an app config nobody else wants): `users/<name>/home.nix`, a home-manager module `modules/default.nix` imports for that person when the file exists. It gets the same arguments as any home module (`user`, `machine`, `pkgs`).
- **A feature anyone could turn on**: `modules/` behind a toggle that's off in the template (the `add-app` skill), committed separately from the person's own folders.

Never a hostname or username check in `modules/`; the post-edit hook flags every machine and user folder name it finds there.

**Forks** of `Warpledge/nixos-config` add their own `machines/` and `users/` folders, leave warpledge's untouched, and trade changes through the `upstream` skill; pushing and opening the pull request stay with the person.

## Workflows

Most tasks have a skill whose description says when to use it (`add-app`, `freetube-sync`, `todo`, `game-troubleshooting`, `vn-setup`/`rpgm-setup`, `disable-package`). The rest:

- **Add an app:** `add-app`. An app not in nixpkgs is an AppImage wrap or a patched `.deb`/tarball before a Flatpak, the last resort.
- **Add a system service:** the toggle goes in `machines/_template/settings.nix` (off) and the machine's `settings.nix`, the module in `modules/nixos/services/<category>/<name>.nix`, the import (`lib.optionals machine.<name>.enable [...]`) in `modules/nixos/default.nix`, and an entry in `setup.sh`'s `services` list.
- **Update flake inputs:** point the user at the user-only `/flake-update [input…]` skill (`nixm upgrade` minus the rebuild).
- **New computer, reinstall or person:** `./setup.sh` / `./setup.sh add-user`, run by the person; never here (sudo, `nixos-rebuild`).
- **Bring Hyprland back:** restore from the `hyprland-backup` branch, re-add `"hyprland"` to `windowManager` in `lib/settings.nix`, set it in the machine's `settings.nix`.
- **Never add a `---` line to `README.md`**: Zed's preview pairs them like front-matter. Verify with `nix run nixpkgs#pulldown-cmark -- < README.md`.

## Window managers, hardware, network, security

- **WM:** niri keybinds, DMS, XDG portals, login and per-machine overrides are in `modules/wm/CLAUDE.md`; read it before changing a WM file, including `machines/<name>/wm/` and `modules/home/variables.nix`, which don't load it. From anywhere: niri spawns with arguments are lists, not strings (a spaced string fails the build), and `QT_QPA_PLATFORM`, `GDK_BACKEND` and `SDL_VIDEODRIVER` keep their X11 fallbacks (`wayland;xcb`, `wayland,x11`, `wayland,x11`) or X11-only apps die when launched from DMS.
- **Hardware:** read the machine's `CLAUDE.md` and `settings.nix` before diagnosing anything machine-specific. **Network** (DNS, Wi-Fi, open ports, Mullvad, blocklists): `modules/nixos/CLAUDE.md`.
- **Security:** only `admin = true` users are in wheel. The sudo NOPASSWD list (`security/auth/sudo.nix`) holds only commands that can't become a root shell, and Omni Settings' polkit helper takes typed values for the caller's own keys only, never file text or Nix. pkexec/polkit elevation, audit tooling (never `vulnix`), AppArmor (test-compile with `apparmor-check`) and SSH are in `modules/nixos/CLAUDE.md`.

## Writing Style

Covers chat replies, `README.md`, `docs/` and commit messages; the `prose-reviewer` subagent holds the full rules and does the cut-only pass. Code blocks, command output, quotes and table cells are exempt.

- Lead with the answer. No upbeat filler, exclamation marks, affirming the user, hedging boilerplate, or a closing line praising the work.
- Chat replies: number any multi-step task, bold the one line not to miss, and end with the single next step when there is one. Group a list over five items under short headings instead of cutting any.
- Avoid the LLM tells: "it's not X, it's Y", fragments for emphasis, stacks of short sentences, rule-of-three lists, rigid parallel bullets, puffery, empty summary sentences, and pet words (delve, robust, seamless, leverage, crucial, ensure, comprehensive, streamline, utilize, enhance). Use contractions and plain words.
- No em dashes in `README.md` or `docs/` prose; a `` `path/` — description `` list dash and README's `**Label:** text` bullets stay.
- `docs/` notes pin time-bound facts to a date or version and cite where a claim came from.
- A chat reply naming packages or upstream projects ends with a **Sources** list from the lookups under **Looking things up**, not memory.

## Formatting Standards

Alejandra (v3.0.0) formats. Headers: **L1** `# FILE PURPOSE (UPPERCASE)` between two `#====...====#` rules, one per file; **L2** `#-- Section Name` between two `#----...----#` rules; **L3** `#--- Item description`; **L4** inline `# comment` (why, not what). A `default.nix` keeps its `imports` in a final `#-- Imports` L2 section. One blank line before each header, none after L1 or between L3 items, one after closing braces. Reformatting a file never deletes content, including commented-out code and disabled options.

### Comment Style

Comment only what the code doesn't make obvious, for someone reading the file cold in six months. One or two lines is normal; a paragraph is a smell. This covers generated scripts and inline strings too.

- **Keep every comment line within 89 columns** (Zed at half-screen width), trailing `# ...` included: shorten first, else move it above the code. Check with `awk 'length>89' <file>`.
- **Do** name what a non-obvious value does, flag a constraint the type system won't catch, and point at where a value must be kept in sync.
- **Don't** write session narrative (how a bug was found, what was tried), restate the code, explain standard Nix or upstream behaviour, list rejected alternatives, or justify at length. A gotcha worth keeping goes in a CLAUDE.md once, with a one-line pointer in the module.
- Comments and user-facing text (Omni Settings descriptions, template comments, README) are plain and short, and keep NixOS's own terms (rebuild, generation, flake input, garbage collection).

## Troubleshooting

`nix flake check` for eval errors, `nixm rebuild --show-trace` (the user runs it) for a full trace, `journalctl -xeu <service>` / `journalctl -b -p err` for logs.

- `infinite recursion` → circular import or self-referencing conditional, or a router reading `user` from module args in `imports` instead of taking it as its first argument
- A message naming `machines/<name>/settings.nix` or `users/<name>/settings.nix` → `lib/settings.nix` rejected a setting; it lists each one
- `attribute missing` → a module reads a setting the `_template` files don't define
- Slow / hung → check `df -h`; try `nix build --offline`

**Rollback:** the user runs `nixm rollback` (rule 1), or picks a generation from the bootloader.

## Looking things up

**Never write a package homepage, description, or option name from memory.**

| Need | Use |
| --- | --- |
| Package metadata | `nix eval --raw nixpkgs#<pkg>.meta.homepage` |
| nixpkgs packages / NixOS + home-manager options | the **nixos** MCP tool (over `nix search` or scraping `search.nixos.org`) |
| Library / SDK / API docs | the **context7** tool (over web search) |
| Upstream releases, tags, issues, files | the **github** MCP tool, read-only (over fetching github.com) |
| How an upstream repo works when context7 has little on it (DMS, niri-flake, stylix, Tsunagu) | the **deepwiki** MCP tool |
| How other public flakes configure something (regex code search) | the **grep** MCP tool (grep.app) |
| An app's own config syntax | `nix-shell -p <pkg> --run 'man <name>'` |

- **Check for a home-manager module before `home.packages`:** `find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix' | head -1`; if it returns a path, use `programs.<pkg>`.
- **Filter at the source.** Man pages, store listings and long files go through `grep`/`sed`, never whole into the conversation. Don't `cat` a folder `CLAUDE.md`: Claude Code loads it when you read a file there. Need several sections of one document? Dump it once to a file and grep that.
- **Stop once you have the answer.** A package's man page is authoritative for its config syntax; skip the nixpkgs derivation. Don't guess doc URLs: after two failed fetches, use a local source.

## Reference Notes (`docs/`)

`docs/CLAUDE.md` indexes the notes and says which to update when (a Minecraft pack's file, a new `~/.local/opt` app, a disabled package, the Android debloat); `docs/personal/` is warpledge's own. Planned work is in `docs/todo/`, handled by the `todo` skill.
