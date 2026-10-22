# CLAUDE.md

## Project

NixOS flake managing **eclipse**, the desktop (Ryzen 5800X3D + RX 9070 XT, 280Hz OLED + 144Hz) and **legion**, the laptop (Legion Slim 5, Ryzen 7735HS + hybrid AMD 680M/RTX 4070, 1600p@165Hz). Nixpkgs unstable; colours from DMS's matugen (default theme Catppuccin Mocha Mauve), fonts and cursor from Stylix. WM: Niri only; Hyprland was removed on 2026-10-21 and its config kept on the `hyprland-backup` branch.

## Critical Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead. When handing back a rebuild, give the user the token-light form to run with `!`: `! nixm rebuild 2>&1 | grep -E "error|Error|failed|Failed" || echo "✓"` (same for `nixm boot`). The edit hook formats each `.nix` file with `alejandra`. Run `nix flake check`, and a machine build even more rarely, only when you can't tell whether a change breaks evaluation or the build: a new module or import, a renamed or unfamiliar option, an input or package change, Nix you aren't sure of. A value changed in an option that already works, or a JSON, Markdown or comment edit, needs neither. Commit without asking (see rule 6); pushing and history rewrites stay with the user.
2. **`git add` new files before `nix flake check`** — the flake won't see untracked files.
3. **Edit existing files in place; don't rewrite them whole.** A rewrite drops commented-out code and disabled options without showing it in review.
4. **Public repo:** no passwords, API keys, tokens, or secrets.
5. **DMS's matugen owns colours; Stylix owns fonts and cursor.** Never hardcode colours, fonts or wallpaper in a module. DMS's theme picker runs matugen, which renders each app's colour file at runtime: DMS's built-in template where it has one (GTK, qt6ct, kitty, Zed), otherwise a repo template in `modules/theme/matugen/` registered under `matugen.templates` (`theme/matugen.nix`), and the app's config includes the rendered file. Rendered files stay plain files nothing else owns: a home-manager store link stops DMS writing or reloading them. Fonts and cursor come from `config.stylix.fonts`/`config.stylix.cursor`; Stylix's colour targets are off except VS Code's, and catppuccin/nix only themes Plymouth. Apps nothing can recolour at runtime keep fixed Catppuccin Mocha Mauve.
6. **Commit format.** Commits you make use the repo's configured git identity (the user's). Messages use Conventional Commits, `type(scope): subject` plus a bullet body (types, scopes and examples in the `commit` skill; the git commit template mirrors them).
7. **No desktop screenshots without permission.** Never capture the screen, a window, or the desktop (screenshot tools, `grim`, niri's screenshot actions, computer-use captures) unless the user has said yes to that specific capture first.
8. **Set only what was asked for.** No extra options, defaults, or "nice to have" settings beyond the request.
9. **Ask before writing new docs or long comments.** A new `.md` file, a new section or note in an existing one, or a new comment longer than a line or two needs the user's yes first; propose it in a sentence and wait. Keeping existing docs accurate needs no approval: CLAUDE.md, AGENTS.md, README rows and links, and the rows and entries a workflow below or a skill keeps current. Neither does a one-line comment where the code would otherwise be unclear.
10. **Ask before saving a memory, and offer where it goes.** Local memory (`~/.claude/projects/.../memory/`) is for private, personal or security-sensitive notes: real names behind stand-ins, personal data, playthrough notes. Anything that would help the config and is safe to publish belongs in the repo (CLAUDE.md, a skill, `docs/`), so it travels with the flake. Propose the note and let the user pick the location before writing it.
11. **`rm` takes literal paths.** Write the absolute path, never `$VAR` (`rm /run/user/1000/a`, not `rm $XDG_RUNTIME_DIR/a`), and run each deletion as its own command, never chained onto a read-only check or hidden in a script.

`AGENTS.md` at the repo root is for the local AI only (opencode and Zed's agent on llama-swap's models): a standalone, condensed version of this file with the same rule numbers, plus guidance for a smaller model (verifying options in upstream source, breaking retry loops, context budget). Keep it in sync: when a rule, path, workflow or gotcha changes here or in a folder's `CLAUDE.md` (condensed under its **Folder rules**), update `AGENTS.md` in the same commit, and never let the two contradict.

Only `.claude/settings.json` is tracked (public); the rest of `.claude/` is gitignored, including `settings.local.json`, where approvals can capture a secret. Before committing a `settings.json` change, and in any CLAUDE.md audit, do the **maintenance check** in `modules/home/programs/ai/CLAUDE.md`, which also explains the permission rules and what the post-edit hook flags. The hook (alejandra plus repo checks) runs on `Write|Edit` only, so edit tracked files with Edit or Write, not `sed` or a heredoc.

Several folders carry their own `CLAUDE.md` (`modules/wm/`, `modules/nixos/`, `docs/`, `modules/home/programs/ai/`, `programs/system/nixos-settings/`, `programs/media/freetube/`). Claude Code loads one when it reads a file in that folder; the pointers below say when to read one first.

## Commands

```bash
nix flake check         # Evaluate all outputs, no build (rule 1 says when)
nix build .#nixosConfigurations.<machine>.config.system.build.toplevel --no-link  # Full build, no activation: catches hash and patch failures that flake check (eval only) misses
alejandra .             # Format all Nix files (v3.0.0 is the standard)
nix fmt .               # Same formatter through the flake; a bare `nix fmt` leaves alejandra 3.0.0 waiting on stdin
deadnix --no-lambda-arg # Find unused function arguments in Nix files
statix check .          # Lint for Nix antipatterns (inherit, empty patterns, etc.)
nixm lint               # Run both deadnix and statix in one shot (wraps the above two)
nixm rebuild            # Apply config (wraps `nh os switch`)
nixm rebuild 2>&1 | grep -E "error|Error|failed|Failed" || echo "✓"  # token-light rebuild
nixm boot               # Build, activate on next boot (`nh os boot`); use when an update bumps glibc/systemd/niri/xwayland-satellite, since live switches froze the desktop on 2026-10-03 (glibc/systemd) and 2026-10-07 (xwayland-satellite)
nixm upgrade            # Update flake inputs + rebuild
nixm flake-update       # Update flake inputs only (no rebuild)
nixm dryrun             # Rebuild without applying
nixm gc                 # GC, keep last 5 generations
nixm rollback           # Pick a generation and switch to it (interactive)
nixm backup             # Back up FreeTube (subs, playlists, history) and Zen bookmarks (as bookmarks.html) to dated ~/SyncBackups folders
nixm freetube-backup    # FreeTube only (app must be closed)
nixm zen-backup         # Zen only
nixm vpn-list           # Show the Android VPN lockdown allowlist on an adb device
nixm vpn-edit           # Edit that allowlist in $EDITOR (adb-writable, no device owner; applies on reboot)
nixm launch-params      # Pick a game launch option (nix-vn/nix-rpgm presets read off PATH) and copy it
nix flake update <name> # Bump a single input
run <pkg> [args]        # Ad-hoc launch a nixpkgs package without installing it (zsh function)
```

`nixm` is an fzf-driven menu defined in `modules/home/nixm.nix` (aliased to `n`). Run `nixm <bogus>` to print the full subcommand list.

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

`lib/settings.nix` turns the settings files into module arguments, so every module can read them. Conditional imports in each subdir's `default.nix` decide what loads.

### Machine and user settings

Two kinds of settings file, each with a template that lists every setting: **`machines/_template/settings.nix`** (one per computer) and **`users/_template/settings.nix`** (one per person). A setting a file leaves out takes the template's value with every true/false turned off, so a new toggle never breaks someone else's machine. `lib/settings.nix` stops evaluation with a message naming the file on a misspelt setting, a wrong kind of value, a port outside 1-65535 in `firewall.*Ports`, an unknown `blocklist.extra` name, a missing `users/<name>/`, an unknown `windowManager`/`kernel`/`cursor`/`cursorSize`/`gpu.type` or user `wallpaper`, a missing `stateVersion`, or a main user without `admin`. Read the templates directly; don't trust this file to stay in sync.

Module arguments:

- NixOS modules get `machine` (the machine's settings plus `name`, `hostName`, `flakePath` and `mainUser`, filled in, and each user's final settings in `machine.users.<name>`) and `anyUser` (each true/false user setting, true when any user on the machine has it on). An app with a system-side piece (an AppArmor profile, Steam, FlareSolverr, the Nautilus extension, the Japanese IME) loads on `anyUser.<app>`.
- Home modules get `machine` and `user`, that user's settings. Home routers (`home/default.nix`, `programs/default.nix`, `programs/gaming/default.nix`, `audio/guitar/default.nix`) read `user` in `imports`, where `_module.args` can't reach, so they take it as a plain first argument (`user: {lib, ...}: {...}`) and their parent imports them with `(import ./gaming user)`.

The settings that need more than their template comment: `users` in a machine file (each name a `users/<name>/` folder; the braces hold that user's settings for this machine only); `mainUser` (owns the repo, runs Syncthing, themes the login screen; may be left null with one user); `flakePath` (null: `/etc/nixos-config`, where `system/user/config-repo.nix` gives every admin (wheel) write access through a default ACL and sets git's `safe.directory`; skipped for a path under `/home/`); `windowManager` (only `"niri"` for now; one per machine: the greeter and portal setup are per compositor); `gpu.*` (`services/hardware/gpu.nix`; null on a machine whose own `hardware/gpu.nix` does it); a user's `admin` (wheel, so sudo and rebuilds; non-admins also skip the docker group); a user's `defaultApps.{browser,textEditor,terminal,fileManager}`, whose choices, `.desktop` ids and launch commands live in `lib/default-apps.nix` (`lib/settings.nix` builds the dropdown choices from it) and which `mime.nix`, `terminal-exec`, `youtube-dispatch` and niri's app binds read through its `forUser`: a pick whose app toggle is off falls to the first of its kind that's on. `mimeapps.list` is forced, so DMS's default-app picker doesn't survive a rebuild; these settings are the place to change defaults. A user's `localAi.code` and `localAi.chat` are lists of the models llama-swap serves, each with its own tuned flags, for opencode's and Zed's model pickers and Open WebUI (the first coding model is the default), and `localAi.edit` picks Zed's inline-suggestion model (null: none); `lib/local-models.nix` lists them with their LM Studio folder, file match and llama.cpp flags, and `lib/settings.nix`, `ai/llama-swap.nix` and `editors/zed.nix` read it. The user template turns on the starter set; `setup.sh` offers the rest from its `apps` list.

NixOS Settings (`programs/system/nixos-settings/`) is a Python GTK4/libadwaita app over these files, imported for every user with no toggle; its root helper is `nixos/system/user/nixos-settings-helper.nix`. Its internals are in `modules/home/programs/system/nixos-settings/CLAUDE.md`: read that before changing the app, the helper, or how the templates are laid out (`#--` sections, `#---` headers, trailing comments), since the app builds its pages from them. Keep the settings files plain data (no `let`, functions or string interpolation), or the app can't parse them.

- `~/.local/opt` bundles (kept out of git) have no category of their own: `media.tonkatsuBox`, `gaming.granblueRelinkMods` and `audio.katanaFloorboard` wrap them; see `docs/local/local-binary-installs.md`. `setup.sh` doesn't offer them.

What a machine or user has on is read from the settings files, never assumed: `users/<name>/settings.nix` holds a person's apps for every machine, and a machine's `users.<name>` block overrides them there. Compare machines with `diff machines/eclipse/settings.nix machines/legion/settings.nix`.

Gotchas. Grep the option name before assuming which file owns it:

- **`boot.kernelModules` silently swallows kernel parameters.** modprobe cannot resolve them, `systemd-modules-load.service` logs `Failed to find module '<param>'` and still exits 0, so the hardening looks applied and is not. Eleven params sat there until 2026-09-22. Check with `grep <param> /proc/cmdline`, not by reading the module. An assertion in `security/hardening/kernel.nix` now fails the build on any `kernelModules` entry containing `=`; a bare flag like `slab_nomerge` still gets through.
- `gaming.steam` is wired in `modules/nixos/gaming/default.nix` (on `anyUser.gaming.steam`, so Steam is installed system-wide for everyone); the rest of `gaming.*` is wired in `home/programs/gaming/default.nix`.
- `media.moku` loads from both trees: the home-manager bundle plus `nixos/services/servers/flaresolverr.nix`. `suwayomi.enable`, `syncthing.enable` and `mullvad.enable` each load one NixOS module (`nixos/services/servers/{suwayomi,syncthing}.nix`, `nixos/security/mullvad/`) that sets its home-manager half through `home-manager.users`: for every user, except Syncthing's app entry, which goes to `mainUser` alone since Syncthing runs as them. `split-tunnel.nix` builds each user's home wrappers from that user's toggles.
- A NixOS module that configures every user's home writes `home-manager.users = lib.mapAttrs (_: _: {...}) machine.users;`, as the theme modules and the machine `wm/` files do. Not `home-manager.sharedModules`: those merge ahead of every other definition, which reorders list options and changes the built files.
- Don't switch the home routers to `lib.modules.importApply`. Its extra nesting reorders the home modules, and options whose type keeps the last definition flip: FreeTube's `secColor` went from the repo's Lavender to catppuccin/nix's Mauve when this was tried on 2026-10-17. The routers set `_file` so errors still name them.
- Non-admin users are added to `nix.settings.allowed-users` (`security/hardening/default.nix`, otherwise `@wheel` only): home-manager's activation runs `nix-env` as each user.
- `nixos/services/runtimes/flatpak.nix` (nix-flatpak) loads on the machine's `flatpak.enable` (on for the desktop, for the Hytale launcher) and declares only Flatseal in `services.flatpak.packages`. Other Flatpak apps aren't in the repo: they're installed by hand, and NixOS Settings' Flatpaks page lists, updates and removes them. The Hytale launcher isn't on Flathub; it's Hypixel's own bundle.
- `machine.kernel` is read in `system/bootloader.nix` (and `modules/default.nix` for the CachyOS overlay); `gaming/performance/kernel.nix` only holds gaming sysctls, boot params and the sched_ext scheduler (`services.scx`, scx_lavd).
- `alejandra`, `claude-code`, `affinity-nix` and `cachyos-kernel` keep their own nixpkgs on purpose (the comments in `flake.nix` say why: a GCC 15 build failure, binary caches that only match their own pin, and CachyOS patches that must match their pin's kernel version), `nix-flatpak` has no nixpkgs input, and `claude-desktop` is source only (`flake = false`). Don't add `inputs.nixpkgs.follows` to them.
- `audio/guitar/` loads when any of `audio.{guitarix,tone3000,katanaFloorboard}` is on; its `default.nix` holds the shared cab IR, tuner and patchbay packages plus the plugin paths, then gates each app on its own toggle.
- `ai/{claude,opencode,lmstudio}.nix` are conditionally imported **and** wrap their body in `config = lib.mkIf user.<toggle> {...}`, so the inner guard never fires on its own. New modules take the conditional import alone.
- Module *loading* goes through `lib.optionals` in a `default.nix`; config *logic* inside a module uses `if/then/else`. Mixing them up is why an option looks wired but has no effect.
- Every setting exists once `lib/settings.nix` has filled the gaps, so read it as a bare path (`user.media.mpv`); `or false` isn't needed.
- Machine-specific hardware lives in the machine's folder, never behind a name check in a shared module: niri monitors and the desktop's DMS bars in `machines/<name>/wm/niri.nix` (the bars through the `dms.extraSettings` option declared in `niri/home/dms/default.nix`), the desktop's DMS GPU widget in `machines/eclipse/hardware/gpu.nix`.
- **Moku is built from source, pinned twice:** the `moku` and `tsunagu` inputs move together, since Tsunagu is the backend each Moku release ships with. The comments in `media/moku/default.nix` explain each patch and hash override, `tsunagu/` holds the Kototoro bridge, and the `moku-bump` skill has the bump order and what each patch fixes. Sources that drive an Android WebView can't work in Tsunagu. Library and extensions live in `~/.local/share/{tsunagu,io.github.MokuProject.Moku}`.

### Conditional import patterns

```nix
# Machine service (nixos/default.nix)
++ lib.optionals machine.clamav.enable [./security/clamav.nix]

# User app (a home router)
++ lib.optionals user.browsers.zen [./browsers/zen]
++ lib.optionals user.media.mpv [./media/mpv.nix]

# System side of a user app (a NixOS router)
++ lib.optionals anyUser.media.mpv [./mpv.nix]

# WM module selection (in modules/default.nix) — the WM is split across both trees
# NixOS imports:
./wm/${machine.windowManager}/session.nix
# home-manager imports, for each user:
./wm/${machine.windowManager}/home

# Per-machine WM override (in machines/<name>/default.nix)
++ (lib.optional (machine.windowManager == "niri") ./wm/niri.nix)
```

`modules/default.nix` is also where `nixpkgs.config` sets `allowUnfree` and `android_sdk.accept_license`, and where `home-manager.backupFileExtension = "bak"` is set. Overlays come from two lists the module system merges: `modules/default.nix` holds the CachyOS kernel one, applied when `machine.kernel == "cachyos"` (`inputs.cachyos-kernel.overlays.pinned`), and `modules/nixos/nix/nixpkgs.nix` holds the unconditional ones (NUR, claude-code, affinity-nix), where a new overlay goes unless a toggle gates it. That file also sets `allowBroken`, so a package nixpkgs marks broken still passes `nix flake check` and only a build shows the failure, and `permittedInsecurePackages`, whose entries name exact versions: an update that moves one to a new version fails eval as insecure until the entry matches. Both `system.stateVersion` and every user's `home.stateVersion` come from the machine's `stateVersion` (`25.11` on the desktop, `26.05` on the laptop since its reinstall), marked DO NOT CHANGE.

### Module layout

- `modules/nixos/` — system: `gaming/` (default, steam, `performance/` esync + gamemode + kernel, `tools/` gamescope + java), `network/` (default, blockers, dns, firewall, networkmanager), `nix/` (default, nh, nixpkgs, substituters), `security/` (auditd, clamav, `apparmor/`, `auth/` keyring + sudo, `hardening/` default + kernel, `mullvad/`), `services/` (desktop, `hardware/` adb + bluetooth + gpu + keyd + power + printing + sound, `runtimes/` docker + flatpak + runners, `servers/` flaresolverr + suwayomi + sunshine + syncthing, ssh), `system/` (bootloader, documentation, packages, `desktop/` input + wayland, `language/` locale + japanese-ime, `tuning/` tweaks + zram, `user/` config-repo + shell + user + nixos-settings-helper)
- `modules/home/` — user: `programs/` (browsers, terminals, editors, ai, shell, fetch, file-browsers, graphics, artcraft (one AppImage wrap per app, built by `mk-app.nix`), audio, media, office, security, system, gaming (`launchers/`, `games/`, `tools/`, `scripts/`), git (`git.nix` + the commit template), android, discord, plus `options.nix`, `utilities.nix` (the general package list) and `user-packages.nix` (a user's `userPackages`, added from NixOS Settings' Packages tab) at its root). `mime.nix`, `nixm.nix`, `services.nix` and `variables.nix` are single files at that level, not directories
  - Wrappers for prebuilt bundles in `~/.local/opt/` (`media/tonkatsu-box.nix`, `gaming/tools/relink-mod-organizer.nix`, `audio/guitar/katana-floorboard.nix`) sit in the folder for what the app is; the payload is intentionally not in the repo. `gaming/tools/reloaded-ii-gbfr.nix` is the exception: a Windows `.exe` its installer puts in `~/Desktop/Reloaded-II - Granblue Fantasy Relink/`, run in GBFR's Proton prefix through `protontricks-launch`
  - `programs/ai/skills/<name>/` and `programs/ai/agents/<name>.md` — Claude Code skills and subagents kept in the repo so every machine gets them, registered in `ai/claude.nix` under `programs.claude-code.{skills,agents}`, beside the pinned plugins and LSP servers; `ai/agent-skills.nix` links the skills into `~/.agents/skills/` for Zed's agent and opencode, which is told to skip `~/.claude/skills/` so it doesn't list them twice. New ones (including what skill-creator writes to `~/.claude/skills/`) move here. Commits go through the `commit` skill, which runs `gitleaks` on the staged diff, and reads the diff itself for what a pattern scanner misses; the `public-repo-auditor` subagent runs only when the user asks. The subagents run at medium effort without CLAUDE.md (`omitClaudeMd`), so each one's file holds everything it needs
  - Subagents: `build-triager` builds one machine's closure and reports only what failed (hand it a build that failed rather than reading the log inline; a clean build never needs it, so the flake-update skill builds inline first); `prose-reviewer` is the cut-only pass in step 5 of **Add an application**; `docs-drift-auditor` checks every CLAUDE.md, AGENTS.md and README.md against the tree, before doc commits and in any CLAUDE.md audit
  - `programs/ai/mcp.nix` — MCP servers shared by Claude Code and opencode. API keys are read at launch from owner-only files in `~/.nixos-config-mcp/`, so they never reach the repo or the store; a new server that needs a key does the same
  - AppImage wraps (`appimageTools`) sit in the folder for what the app is, not how it is packaged: `gaming/games/feedback.nix`, `media/streamlink-twitch-gui.nix`, `media/boorusama.nix`. The payload is hash-pinned into the store, so unlike the `~/.local/opt` wrappers nothing lives outside git (see `docs/local/appimage-wraps.md`)
  - `default.nix` carries a `clearStaleBackups` activation hook that deletes `*.bak` under `~/.config`, `~/.local/{share,state}` before `checkLinkTargets`. This is why HM activation never fails on leftover backups. Don't remove it when debugging a "file exists" error; find the real conflicting file instead.
  - `programs/media/freetube/` — mirrored settings and blocklist; its `CLAUDE.md` explains the mirroring (close FreeTube before rebuilding) and what stays out of the repo
- `modules/wm/niri/` — `session.nix` (NixOS: turns the WM on, login screen, keyring unlock) and `home/` (home-manager, everything else, including DankMaterialShell (DMS)); `modules/wm/dms-mutable.nix` is the settings merge its DMS module imports, and `modules/wm/dms-polkit/` the patch it imports that makes DMS's polkit password prompt a full-screen modal, with `PolkitScreenBlockers.qml` covering the other monitors
- `modules/theme/` — `matugen.nix` (the `matugen.templates` option, written to `~/.config/matugen/dms/configs/repo.toml`, which DMS appends to every matugen run) and the repo templates in `matugen/`, converted from the Catppuccin ports with Mocha's colours mapped to DMS roles and `dank16` slots; `dms.nix`, the default DMS theme (Catppuccin Mocha Mauve with Crust as Base, for contrast behind translucent windows), seeded once so the picker's choice sticks; `gtk.nix` (adw-gtk3 plus DMS's `dank-colors.css`) and `qt.nix` (qt5ct/qt6ct on matugen's palette, `kdeglobals` from DMS's KDE scheme); `stylix.nix` for fonts and cursor; `catppuccin.nix` for Plymouth; `fonts.nix`. `gtk.css`, `qt5ct.conf` and `qt6ct.conf` are copied in place on activation rather than linked: DMS only reloads running apps through files it can read and touch. GTK 4 apps still recolour only on restart, except NixOS Settings, which reloads `dank-colors.css` itself; Zen, GoofCord and KDE apps also read theirs at start. A template whose `{{ }}` placeholders sit in a `.css` file runs Zed's biome language server out of memory, so those are named `.css.matugen`. No module sets the wallpaper: DMS picks it at runtime (`Mod+W`) and `theme/wallpapers/` holds the images
- `modules/nixos/security/mullvad/` — `daemon.nix` (daemon settings), `gui.nix` (tray app, a home-manager module) and `split-tunnel.nix` (system and home wrappers). Imported from `nixos/default.nix`, gated on `machine.mullvad.enable`
- `lib/settings.nix` — reads a machine's settings and its users', fills them in from the templates, checks them, and returns `machine` and `anyUser`
- `lib/mutable-merge.jq` — the merge that keeps GUI changes across rebuilds, shared by `wm/dms-mutable.nix`, `editors/zed.nix` and `file-browsers/dux-files.nix`. Zed's template is `~/.config/zed/declarative-settings.json`, whose values the reset button on NixOS Settings' Zed switch puts back into `settings.json`; theme and fonts are locked
- `machines/<name>/` — `default.nix` (machine entry), `settings.nix`, `hardware/` (`gpu.nix`, `hardware-configuration.nix`), `wm/<wm>.nix` (per-WM machine overrides for every user: monitors, GPU env vars, autostart, the desktop's DMS bars)
- `machines/_template/` and `users/_template/` — what `setup.sh` copies; their `settings.nix` files are also the full setting lists and the defaults. `machines/_template/hardware/hardware-configuration.nix` throws until it's replaced
- `users/<name>/settings.nix` — one person's account and apps (`users/warpledge/` for the user)
- `setup.sh` — sets up a new computer (moves the clone to `/etc/nixos-config` with a link at the old place, `machines/<name>/` from the template, `hardware-configuration.nix`, locale and keyboard from the installer's `configuration.nix`, disk-unlock lines into `hardware/boot.nix`, GPU from sysfs, each connected monitor's preferred resolution with a scale the user picks into `wm/<wm>.nix`, the zen kernel without asking (cachyos has no binary cache, so it compiles locally), a `users/<name>/` per new person, then `nixos-rebuild boot`; or a reinstall of a machine already in `machines/`, which keeps its settings and replaces only `hardware-configuration.nix`, `hardware/boot.nix` and, if you agree, `stateVersion`), `add-user`, `build`, and `share` (that move alone, for a clone set up before it). It stages its files with git and asks before anything that needs sudo
- `machines/eclipse/` also has `hardware/storage.nix`, which unlocks the LUKS game drives after boot from key files on the encrypted root (crypttab).
- `machines/legion/` also has `hardware/swapfile.nix` and `minecraft-servers/` (GTNH + TerraFirmaGreg server definitions, plus `mcservers.nix`, an fzf picker over them). `minecraft-servers/` is a **home-manager** module injected from `machines/legion/default.nix` via `home-manager.users.${machine.mainUser}.imports`, not a NixOS module, since the servers live in the main user's `~/Documents`.

### Where to place things

| Scope | Path |
| --- | --- |
| Shared system | `modules/nixos/` |
| Shared user | `modules/home/` |
| Per-machine hardware/entry | `machines/<name>/` |
| Machine toggle (services, kernel, WM, locale) | `machines/<name>/settings.nix`, listed in `machines/_template/settings.nix` |
| User toggle (apps, account) | `users/<name>/settings.nix`, listed in `users/_template/settings.nix` |
| One user's change on one machine | the `users.<name>` block of `machines/<machine>/settings.nix` |
| WM internals | `modules/wm/{wm}/` |
| Mullvad VPN | `modules/nixos/security/mullvad/` |
| Per-machine WM overrides | `machines/<name>/wm/{wm}.nix` (`niri.nix`) |

## Workflows

**Add an application** (the `add-app` skill runs these steps, then checks the wiring):
For an app not in nixpkgs, wrap upstream's AppImage (`appimageTools`) or patch its `.deb` or tarball with `autoPatchelfHook` first; a Flatpak is the last resort (Flatpak runtimes update under the app with no way to pin them), and the user wants Flatpak gone once Hytale has another route.

1. Add the toggle to `users/_template/settings.nix` (`false` unless every new user should get it), turn it on in `users/warpledge/settings.nix` (or in one machine's `users.warpledge` block), and add it to the `apps` list in `setup.sh` unless it needs a `~/.local/opt` bundle
2. Create the module in the right subdir (`modules/home/programs/...`)
3. Add the conditional import (`lib.optionals user.<category>.<app> [...]`) to `modules/home/programs/default.nix`, the router under `programs/`; a `gaming.*` app goes in `programs/gaming/default.nix`, which routes its own launchers, games and tools, and a guitar app goes in `audio/guitar/default.nix`, with its toggle added to that folder's gate in `programs/default.nix`. The other nested `default.nix` files (`browsers/zen/`, `media/{freetube,moku}/`, and `gaming/launchers/xsystem4/` with one module) are module bundles, not routers
4. `git add` new files → `nix flake check` (a new module and its import are what rule 1 means by uncertain; do not rebuild; hand it back)
5. Give any prose the task wrote or edited a cut-only revision pass before handing back: remove words, add none. No new information, no new claims, no rephrasing that smuggles either in. See **Writing Style**.
6. Add it to the matching `<details>` table under **Components** in `README.md` (plus `## Structure` for a new directory, `## Flake Inputs` for a new input), and its link-reference definition at the bottom: the README is the public-facing doc and drifts easily.

   Grep for the two regions, then edit those lines directly:

   ```bash
   grep -n '^| \*\*' README.md          # Components table rows
   grep -n '^\[.*\]: http' README.md    # link-reference block
   ```

   **Never add a `---` line to `README.md`.** Zed's preview pairs them like front-matter delimiters and shows the sections between as raw text, while GitHub renders fine. Section breaks come from `##` headings alone. Verify markdown with `nix run nixpkgs#pulldown-cmark -- < README.md`, not the preview pane.

**Update FreeTube state** (blocklist or settings), asked for as "I blocked more" / "sync freetube": the `freetube-sync` skill; background in `programs/media/freetube/CLAUDE.md`.

**Update flake inputs:** the user-only `flake-update` skill (`/flake-update [input…]`) does what `nixm upgrade` does, minus the rebuild. It builds this machine without activating it, fixes or switches off failures and rechecks disabled packages, then hands back the rebuild command. Asked to update the flake, point the user at it.

**Add a system service:** same flow, but the toggle goes in `machines/_template/settings.nix` (off) and the machine's `settings.nix`, the module in `modules/nixos/services/<category>/<name>.nix`, the import (`lib.optionals machine.<name>.enable [...]`) in `modules/nixos/default.nix`, and its entry in the `services` list of `setup.sh`.

**New computer, reinstall or person:** `./setup.sh` on the new computer (it offers to reinstall a machine already in `machines/` instead), `./setup.sh add-user` for a person. It's for people installing this config; don't run it here (its last steps use sudo and `nixos-rebuild`).

**Bring Hyprland back:** restore it from the `hyprland-backup` branch (`git show hyprland-backup --stat` lists what was there), re-add `"hyprland"` to `windowManager` in `lib/settings.nix`, then set it in the machine's `settings.nix`.

**Customize WM:** edit `modules/wm/{wm}/home/...` for shared behavior, or `machines/<name>/wm/{wm}.nix` for per-machine overrides (monitors, GPU env vars).

## Window Managers

Niri keybind syntax, DMS, XDG portals, login and the per-machine overrides are in `modules/wm/CLAUDE.md`. Read it before changing a WM file, including `machines/<name>/wm/` and `modules/home/variables.nix`, which don't load it on their own. Two rules that bite from anywhere: Niri spawns with arguments must be lists, not strings (an assertion fails the build on a spaced string), and `QT_QPA_PLATFORM`, `GDK_BACKEND` and `SDL_VIDEODRIVER` keep their X11 fallbacks (`wayland;xcb`, `wayland,x11`, `wayland,x11`) or X11-only apps die when launched from DMS.

## Hardware

**Which machine:** run `hostname` (`eclipse` for the desktop or `legion` for the laptop, which match their folders in `machines/`) before diagnosing anything machine-specific, and read that machine's `machines/<name>/` and `settings.nix`; the two differ in GPU, power management and their settings files.

**Desktop:** AMD-only (RX 9070 XT direct rendering), performance governor. Suspend is disabled because the RX 9070 XT doesn't resume cleanly. LACT runs with amdgpu overdrive on (`ppfeaturemask` is the kernel default plus the overdrive bit), set in `machines/eclipse/hardware/gpu.nix`. GameMode has no `gpu` section: its `amd_performance_level = "high"` pinned the card to the 2400 MHz game clock (about 20% slower in Superposition), so don't add it back.
**Laptop:** TLP power mgmt, hybrid GPU defaults to AMD 680M; route apps to RTX 4070 with `nvidia-offload <app>`. WM-specific GPU vars live in `machines/legion/wm/`. It doubles as the Minecraft server host, so sleep, suspend and hibernate are off, the lid and power key are ignored, and DMS auto-lock is off under niri.

## Network

DNS (systemd-resolved, DoT), Wi-Fi (iwd), which ports each module opens, Mullvad and its split tunnel, and the hosts blocklists are in `modules/nixos/CLAUDE.md`.

## Security

LUKS, kernel hardening, AppArmor, GNOME Keyring, auditd. Mullvad VPN as above. Only users with `admin = true` are in wheel. nh, and so `nixm`, elevates with pkexec (`NH_ELEVATION_STRATEGY` in `nix/nh.nix`, whose polkit rule keeps the authorization for the calling process so a rebuild asks once), so `nixm rebuild` prompts in DMS's polkit dialog whether or not a terminal is attached, as with `! nixm rebuild` in Claude Code. `modules/wm/dms-polkit/` patches DMS so that dialog is a full-screen modal holding the keyboard until it closes, and dims every other monitor with a layer that takes clicks and, under niri, the keyboard (niri honours a layer's keyboard grab only on the active monitor, and a click elsewhere changes it); plain `sudo` typed in a terminal still asks there, and GPG and keyring prompts (pinentry-gnome3, gcr-prompter) aren't polkit, so they keep their own windows. Wheel needs a password for sudo; the NOPASSWD list in `security/auth/sudo.nix` covers only sync, poweroff, reboot and shutdown. Keep it to commands that cannot be turned into a root shell (sed, systemctl, nixos-rebuild and dmesg all can). Non-admins can't run sudo at all (`execWheelOnly`); their one root path is NixOS Settings' polkit helper (see **Machine and user settings**), which must keep taking typed values for the caller's own keys only, never file text or Nix. Its admin requests (rebuild as-is, switch to a generation) check wheel membership first.

Audit tooling (`lynis`, `sbomnix`/`vulnxscan`, off while broken per `docs/nixpkgs/disabled-packages.md`; never `vulnix`), the AppArmor profiles (test-compile with the `apparmor-check` skill) and SSH/fail2ban are in `modules/nixos/CLAUDE.md`.

## Writing Style

Covers chat replies, `README.md`, `docs/` and commit messages; code comments follow
**Comment Style** below. The `prose-reviewer` subagent holds the full rules and does the
cut-only pass.

- Lead with the answer. No upbeat filler, exclamation marks, affirming the user,
  hedging boilerplate ("It's worth noting"), or a closing line praising the work.
- Avoid the LLM tells: "it's not X, it's Y", fragments for emphasis, stacks of short
  sentences, rule-of-three lists, rigid parallel bullets, puffery (say what a thing does,
  not how well), empty summary sentences, marketing nouns, and pet words (delve, robust,
  seamless, leverage, crucial, ensure, comprehensive, streamline, utilize, enhance).
- Use contractions, plain words, and varied sentence length and openings.
- No em dashes in `README.md` or `docs/` prose; a `` `path/` — description `` list dash is
  structure and stays, as does README's `**Label:** text` bullet style.
- `docs/` notes pin time-bound facts to a date or version, name the condition behind a
  vague frequency, and cite where a claim came from.
- A chat reply naming packages or upstream projects ends with a **Sources** list, taken
  from the lookups under **Looking things up**, not memory.
- Code blocks, command output, quotes and table cells are exempt.

## Formatting Standards

Alejandra (v3.0.0) is the formatter. Header hierarchy used throughout the repo:

- **L1** — `# FILE PURPOSE (UPPERCASE)` between two `#====...====#` rules, one per file
- **L2** — `#-- Section Name` (title case) between two `#----...----#` rules
- **L3** — `#--- Item description`
- **L4** — inline `# comment` (explain *why*, not *what*)

A `default.nix` that imports anything keeps its `imports` in a final `#-- Imports` L2 section, after the rest of its config.

Spacing: 1 blank line before each header level, none after L1 (code starts on the next line), none between L3 items, 1 after closing braces. Alejandra collapses multiple blank lines to one.

When reformatting an existing file: add headers, normalize spacing, convert inline markers to the hierarchy above. **Never delete content**, including commented-out code and disabled options.

### Comment Style

**Keep comments short. A comment earns its place by saving the next reader a trip to the docs, not by narrating.** One or two lines is normal; a paragraph is a smell.

**Keep every comment line within 89 columns**, trailing `# ...` comments included. The user reads files in Zed at half-screen width, where a longer line wraps onto a second row. Shorten the wording first (a detail kept elsewhere, such as a doc, can be pointed at instead), and if it still doesn't fit, move the comment onto its own line above the code. Check with `awk 'length>89' <file>`.

Write comments for someone reading this file cold in six months:

- **Do** name what a non-obvious option or value does, flag a constraint the type system won't catch (`margin` must be 0 when `anchor_gap` is false), and point at where a value came from when it must be kept in sync.
- **Don't** write session narrative: how a bug was found, what was tried first, what "we" discovered, or which approach got rejected. If a gotcha is worth keeping, it goes in CLAUDE.md once, and the module gets a one-line pointer.
- **Don't** restate the code (`# Set autotile to true`), explain standard Nix or upstream behavior, list alternatives that were not chosen, or embed verification/debugging steps.
- **Don't** justify a decision at length. State the constraint in a clause; skip the reasoning chain.

This applies to generated scripts and inline strings too, not just Nix attributes.

## Troubleshooting

```bash
nix flake check                  # Eval errors (fastest)
nixm rebuild --show-trace        # Full trace (ask the user to run this)
journalctl -xeu <service>        # Service logs
journalctl -b -p err             # Errors this boot
```

Common errors:
- `infinite recursion` → circular import or self-referencing conditional, or a router reading `user` from module args in `imports` instead of taking it as its first argument
- A message naming `machines/<name>/settings.nix` or `users/<name>/settings.nix` → `lib/settings.nix` rejected a setting; it lists each one
- `attribute missing` → a module reads a setting the `_template` files don't define
- Slow / hung → check `df -h`; try `nix build --offline`

**Rollback:** the user runs `nixm rollback` (rule 1), or picks a generation from the bootloader.

**Laptop GPU:** `lspci | grep -i vga`, `env | grep -E 'DRI|VDPAU|LIBVA|VK'`. Configs: `machines/legion/hardware/gpu.nix` and `machines/legion/wm/niri.nix`. Verify offload with `nvidia-offload glxinfo | grep "OpenGL renderer"`.

**A game crashes, freezes or won't start:** the `game-troubleshooting` skill has the logging, hang-vs-crash and native-engine steps, and indexes the per-game notes in `docs/gaming/`.

**Upscaling a VN or RPG Maker game:** the `vn-setup` and `rpgm-setup` skills pick the nix-vn/nix-rpgm preset and hand back the launch option.

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

**Check for a home-manager module before falling back to `home.packages`.** Many programs have one and it is the better module:

```bash
find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix' | head -1
```

If that returns a path, read it and use `programs.<pkg>` instead.

**Filter at the source.** Man pages, store listings, and long files go through `grep`/`sed`. Never dump one into the conversation. Target the path you want rather than listing a directory, and if you need several sections of the same document, dump it once to a file and grep that.

**Stop once you have the answer.** A package's own man page is authoritative for its config syntax; don't go on to read the nixpkgs derivation or build inputs, which describe how it is built, not how it is configured. Don't guess documentation URLs: if two web fetches fail, fall back to a local source.

## Reference Notes (`docs/`)

Notes under `docs/` (security, gaming, audio, android, local installs, disabled packages, WM) are indexed in `docs/CLAUDE.md`, which says which to update when. Keep them current: a Minecraft pack's `docs/gaming/minecraft_servers/<pack>/` file when that pack's config, mods or settings change; a `docs/local/local-binary-installs.md` entry per new `~/.local/opt` app; a `docs/nixpkgs/disabled-packages.md` row per package an update forces off (the `disable-package` skill); and the Android debloat after each ZUI OTA (the `android-debloat-redo` skill).

Planned work lives under `docs/todo/`, one file per task, named after it (`todo/affinity-setup.md`). **When the user says "add X to the todo", write a new file there** holding what the task is, why they want it, what the repo already has toward it, the steps left, and any research already done (links, versions, gotchas). Update the file rather than starting a second one for the same task, and delete it once the work is done. These are working notes: no `README.md` or Components entry.
