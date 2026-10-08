# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

NixOS flake managing **Desktop** (Ryzen 5800X3D + RX 9070 XT, 280Hz OLED + 144Hz) and **Laptop** (Legion Slim 5, Ryzen 7735HS + hybrid AMD 680M/RTX 4070, 1600p@165Hz). Nixpkgs unstable, Catppuccin Mocha Mauve via Stylix. Active WM: Niri; a Hyprland module also exists.

## Critical Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead. Validation you SHOULD run yourself before reporting done: `alejandra .` → `git add <new files>` → `nix flake check`. Commit only when asked (see rule 6); pushing and history rewrites stay with the user.
2. **`git add` new files before `nix flake check`** — the flake won't see untracked files.
3. **Edit existing files in place; don't rewrite them whole.** A rewrite drops commented-out code and disabled options without showing it in review.
4. **Public repo:** no passwords, API keys, tokens, or secrets.
5. **Stylix owns theming.** Never set colors, fonts, or wallpaper in a module: enable the program's theming target and let Stylix supply the palette. Hardcoded values conflict with or silently override the theme. catppuccin/nix (`theme/catppuccin.nix`) auto-enables its ports beside Stylix; where both theme an app, one target is switched off in `theme/`. Apps neither covers carry upstream's Catppuccin file (Zen's `userChrome.css`/`userContent.css`).
6. **No agent attribution in commits.** Commits you make use the repo's configured git identity (the user's), and every commit message or PR description carries no `Co-Authored-By:` trailer, no "Generated with" line, and no mention of Claude or any agent. The user is the sole author of every commit. Messages use Conventional Commits, `type(scope): subject` plus a bullet body (types, scopes and examples in the `commit` skill; the git commit template mirrors them).
7. **No desktop screenshots without permission.** Never capture the screen, a window, or the desktop (screenshot tools, `grim`, niri's screenshot actions, computer-use captures) unless the user has said yes to that specific capture first.
8. **Set only what was asked for.** No extra options, defaults, or "nice to have" settings beyond the request.

`AGENTS.md` at the repo root is a second, shorter ruleset for other agents (opencode reads it *instead of* `CLAUDE.md`). The two must not contradict each other: when a rule here changes, check whether `AGENTS.md` says the same.

Only `.claude/settings.json` is tracked (public); the rest of `.claude/` is gitignored, including `settings.local.json`, where "always allow" approvals land and can capture a secret. **Maintenance check:** before committing a `settings.json` change, and in any CLAUDE.md audit, read both files for tokens, keys, credentialed URLs or private paths; nothing secret goes in `settings.json`, and stale or sensitive local approvals get pruned. Bash allow rules stay read-only, since in auto mode a matching allow rule skips the safety classifier (`autoMode.classifyAllShell` is off by default). `alejandra` is the one writer (the edit hook runs it anyway). `deadnix --no-lambda-arg` (with or without ` .`) and `nix flake check`/`show`/`metadata` are exact rules, because a prefix rule would also let risky flags through (deadnix's `--edit`). `nix build`/`nix eval`/`nix log` stay off: `--impure --expr` reads and sends out any file, and `--option` can enable `builtins.exec`. Deny rules enforce rules 1 and 7 (rebuild, activation, boot, upgrade, rollback and screenshot commands), so an approved capture runs on the user's side with `!`. The `PostToolUse` hook, `modules/home/programs/ai/hooks/post-edit.sh`, runs `alejandra` on each edited `.nix` file and flags three things: a new `---` line in `README.md`, a color literal outside `theme/` (rule 5), and host toggle drift after a `settings.nix` edit. The hook matches `Write|Edit` only, so a file changed through Bash (`sed`, a heredoc) skips the formatting and all three checks; edit tracked files with Edit or Write.

## Commands

```bash
nix flake check         # Validate syntax (run first, fastest feedback)
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link  # Full build, no activation: catches hash and patch failures that flake check (eval only) misses
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
nix flake update <name> # Bump a single input
run <pkg> [args]        # Ad-hoc launch a nixpkgs package without installing it (zsh function)
```

`nixm` is an fzf-driven menu defined in `modules/home/nixm.nix` (aliased to `n`). Run `nixm <bogus>` to print the full subcommand list.

## Architecture

```
flake.nix
  → hosts/{hostname}/default.nix             (host entry)
    → hosts/{hostname}/settings.nix          (toggles, passed as specialArgs)
    → modules/default.nix                    (NixOS + home-manager wiring)
      → modules/{nixos,home}/                (modular configs)
      → modules/wm/${windowManager}/         (active WM only)
```

`hostConfig` from each host's `settings.nix` is threaded through `specialArgs`, so every module can read it. Conditional imports in each subdir's `default.nix` decide what loads.

### hostConfig

The authoritative list of toggles is **`hosts/{hostname}/settings.nix`**. Read it directly, don't trust this file to stay in sync. Current shape (desktop and laptop are kept symmetrical):

- `username` — read by `flake.nix` itself (`inherit (hostConfig) username`), not just by modules
- `windowManager` — `"hyprland" | "niri"`
- `kernel` — `"zen" | "latest" | "xanmod" | "cachyos"`
- Service toggles: `mullvad.enable` (plus `mullvad.splitTunnel`, a list of command names routed around the VPN), `clamav.enable`, `docker.enable`, `discord.arrpc.enable`, `scrcpy.enable`, `ssh.enable`, `suwayomi.enable`, `syncthing.enable`
- Attribute-set toggles: `browsers.{zen,mullvad,helium,ferdium}`, `terminals.{kitty,ghostty}`, `editors.{helix,zed}`, `fileBrowsers.{nautilus,yazi}`, `media.{mpv,spotify,freetube,videoTrimmer,moku,streamlinkTwitchGui,seanime,boorusama,tonkatsuBox}`, `graphics.{blender,krita,affinity}`, `audio.{reaper,guitarix,tone3000,katanaFloorboard}`, `office.{thunderbird,obsidian,homebank}`, `security.{bleachbit,keepassxc}`, `gaming.{steam,heroic,prismlauncher,lutris,faugus,twintail,hytale,easyrpg,feedback,rocksmith,r2modman,pathOfBuilding,granblueRelinkMods}`, `japanese.{ime,vn}`
- `~/.local/opt` bundles (kept out of git) have no category of their own: `media.tonkatsuBox`, `gaming.granblueRelinkMods` and `audio.katanaFloorboard` wrap them; see `docs/local/local-binary-installs.md`
- AI tools: `claude.enable`, `opencode.enable`, `lmstudio.enable`

Desktop and laptop should stay byte-identical apart from the header comment and a short list of deliberate differences. As of 2026-10-08 those are true on desktop and false on laptop: `gaming.{heroic,easyrpg,hytale,r2modman,pathOfBuilding}`, `discord.arrpc.enable`, `suwayomi.enable`, `media.{moku,seanime,boorusama,tonkatsuBox}`. Verify with `diff hosts/desktop/settings.nix hosts/laptop/settings.nix` before assuming.

Gotchas. Grep the option name before assuming which file owns it:

- **`boot.kernelModules` silently swallows kernel parameters.** modprobe cannot resolve them, `systemd-modules-load.service` logs `Failed to find module '<param>'` and still exits 0, so the hardening looks applied and is not. Eleven params sat there until 2026-09-22. Check with `grep <param> /proc/cmdline`, not by reading the module. An assertion in `security/hardening/kernel.nix` now fails the build on any `kernelModules` entry containing `=`; a bare flag like `slab_nomerge` still gets through.
- `gaming.steam` is wired in `modules/nixos/gaming/default.nix` and `gaming.hytale` only gates Flatpak in `nixos/default.nix`; the rest of `gaming.*` is wired in `home/programs/gaming/default.nix`.
- `media.moku` loads from both trees: the home-manager bundle plus `nixos/services/servers/flaresolverr.nix`. `suwayomi.enable`, `syncthing.enable` and `mullvad.enable` each load one NixOS module (`nixos/services/servers/{suwayomi,syncthing}.nix`, `nixos/security/vpn/mullvad/`) that sets its home-manager half through `home-manager.users.${username}`.
- `nixos/services/runtimes/flatpak.nix` (nix-flatpak) loads only while a Flatpak app's toggle is on, today `gaming.hytale`, the one Flatpak left. Hytale isn't on Flathub: its launcher is Hypixel's own bundle, installed by hand, so `services.flatpak.packages` stays empty for it. A new Flatpak app adds its toggle to that condition in `nixos/default.nix`, or `services.flatpak.packages` doesn't exist for it to set.
- `hostConfig.kernel` is read in `system/bootloader.nix` (and `modules/default.nix` for the CachyOS overlay); `gaming/performance/kernel.nix` only holds gaming sysctls and boot params.
- `alejandra`, `claude-code`, `affinity-nix` and `cachyos-kernel` keep their own nixpkgs on purpose (the comments in `flake.nix` say why: a GCC 15 build failure, binary caches that only match their own pin, and CachyOS patches that must match their pin's kernel version), and `nix-flatpak` has no nixpkgs input. Don't add `inputs.nixpkgs.follows` to them.
- `audio/guitar/` loads when any of `audio.{guitarix,tone3000,katanaFloorboard}` is on; its `default.nix` holds the shared cab IR, tuner and patchbay packages plus the plugin paths, then gates each app on its own toggle.
- `ai/{claude,opencode,lmstudio}.nix` are conditionally imported **and** wrap their body in `config = lib.mkIf hostConfig.<toggle> {...}`, so the inner guard never fires on its own. New modules take the conditional import alone.
- Module *loading* goes through `lib.optionals` in a `default.nix`; config *logic* inside a module uses `if/then/else`. Mixing them up is why an option looks wired but has no effect.
- Reach nested attrs that may not exist with `hostConfig.feature.sub or false`, never a bare path.
- **Moku is built from source, pinned twice:** the `moku` and `tsunagu` inputs move together, since Tsunagu is the backend each Moku release ships with. The comments in `media/moku/default.nix` explain each patch and hash override, `tsunagu/` holds the Kototoro bridge, and the `moku-bump` skill has the bump order and what each patch fixes. Sources that drive an Android WebView can't work in Tsunagu. Library and extensions live in `~/.local/share/{tsunagu,io.github.MokuProject.Moku}`.

### Conditional import patterns

```nix
# Single boolean
++ lib.optionals hostConfig.clamav.enable [./security/av/clamav.nix]

# Attribute-set item
++ lib.optionals hostConfig.browsers.zen [./browsers/zen]
++ lib.optionals hostConfig.media.mpv [./media/mpv.nix]

# WM module selection (in modules/default.nix) — the WM is split across both trees
# NixOS imports:
./wm/${hostConfig.windowManager}/session.nix
# home-manager imports:
./wm/${hostConfig.windowManager}/home

# Per-host WM override (in hosts/{hostname}/default.nix)
++ (lib.optional (hostConfig.windowManager == "niri") ./wm/niri.nix)
```

`modules/default.nix` is also where `nixpkgs.config` sets `allowUnfree` and `android_sdk.accept_license`, and where `home-manager.backupFileExtension = "bak"` is set. Overlays come from two lists the module system merges: `modules/default.nix` holds the CachyOS kernel one, applied when `hostConfig.kernel == "cachyos"` (`inputs.cachyos-kernel.overlays.pinned`), and `modules/nixos/nix/nixpkgs.nix` holds the unconditional ones (NUR, claude-code, affinity-nix), where a new overlay goes unless a toggle gates it. That file also sets `allowBroken`, so a package nixpkgs marks broken still passes `nix flake check` and only a build shows the failure, and `permittedInsecurePackages`, whose entries name exact versions: an update that moves one to a new version fails eval as insecure until the entry matches. Both `system.stateVersion` and `home.stateVersion` are pinned to `25.11`, marked DO NOT CHANGE.

### Module layout

- `modules/nixos/` — system: `gaming/` (default, `launchers/` steam, `performance/` esync + gamemode + kernel, `tools/` gamescope + java), `network/` (default, blockers, dns, firewall, networkmanager), `nix/` (default, nh, nixpkgs, substituters), `security/` (`apparmor/`, `audit/` auditd, `auth/` keyring + sudo, `av/` clamav, `hardening/` default + kernel, `vpn/mullvad/`), `services/` (desktop, `hardware/` adb + keyd + power + sound, `runtimes/` docker + flatpak + runners, `servers/` flaresolverr + suwayomi + syncthing, ssh), `system/` (bootloader, documentation, packages, `desktop/` input + wayland, `language/` locale + japanese-ime, `tuning/` tweaks + zram, `user/` shell + user)
- `modules/home/` — user: `programs/` (browsers, terminals, editors, ai, shell, fetch, file-browsers, graphics, audio, media, office, security, gaming (`launchers/`, `games/`, `tools/`, `scripts/`), git (`git.nix` + the commit template), utilities (`utilities.nix`, the general package list), android, discord, plus `options.nix` at its root). `mime.nix`, `nixm.nix`, `services.nix` and `variables.nix` are single files at that level, not directories
  - Wrappers for prebuilt bundles in `~/.local/opt/` (`media/tonkatsu-box.nix`, `gaming/tools/relink-mod-organizer.nix`, `audio/guitar/katana-floorboard.nix`) sit in the folder for what the app is; the payload is intentionally not in the repo. `gaming/tools/reloaded-ii-gbfr.nix` is the exception: a Windows `.exe` its installer puts in `~/Desktop/Reloaded-II - Granblue Fantasy Relink/`, run in GBFR's Proton prefix through `protontricks-launch`
  - `programs/ai/skills/<name>/` and `programs/ai/agents/<name>.md` — Claude Code skills and subagents kept in the repo so every host gets them, registered in `ai/claude.nix` under `programs.claude-code.{skills,agents}`, beside the pinned plugins and LSP servers. New ones (including what skill-creator writes to `~/.claude/skills/`) move here. Commits go through the user-only `commit` skill, which runs `gitleaks` on the staged diff and the `public-repo-auditor` subagent
  - Subagents: `build-triager` builds one host's closure and reports only what failed (hand it a build that failed rather than reading the log inline; a clean build never needs it, so the flake-update skill builds inline first); `prose-reviewer` is the cut-only pass in step 5 of **Add an application**; `docs-drift-auditor` checks CLAUDE.md, AGENTS.md and README.md against the tree, before doc commits and in any CLAUDE.md audit
  - `programs/ai/mcp.nix` — MCP servers shared by Claude Code and opencode. API keys are read at launch from owner-only files in `~/.nixos-config-mcp/`, so they never reach the repo or the store; a new server that needs a key does the same
  - AppImage wraps (`appimageTools`) sit in the folder for what the app is, not how it is packaged: `gaming/games/feedback.nix`, `media/streamlink-twitch-gui.nix`, `media/boorusama.nix`. The payload is hash-pinned into the store, so unlike the `~/.local/opt` wrappers nothing lives outside git (see `docs/local/appimage-wraps.md`)
  - `default.nix` carries a `clearStaleBackups` activation hook that deletes `*.bak` under `~/.config`, `~/.local/{share,state}` before `checkLinkTargets`. This is why HM activation never fails on leftover backups. Don't remove it when debugging a "file exists" error; find the real conflicting file instead.
  - `programs/media/freetube/` — `settings.nix` (mirrored from the app), `blocked-channels.nix` (~870 channel ids in one flat list, sorted by lowercased name under `LC_ALL=C`) and `youtube-dispatch.nix`, the link handler `mime.nix` points `webLinks` at. The first two are **mirrored**: the home-manager module copies `hm_settings.db` over `settings.db` **only when the declared content changes**, and FreeTube rewrites that file from memory when it exits, so close FreeTube before rebuilding, or the copy is clobbered and stays clobbered until the module changes again. Blocklist entries are emitted with a `preferredName` and a placeholder `icon`, because FreeTube re-resolves every entry missing either one, at one API call each. Subscriptions, profiles, playlists and history are **not** in the repo: they are personal data and this flake is public. `nixm freetube-backup` exports them to a dated folder under `~/SyncBackups/<hostname>/FreeTube` instead, in FreeTube's own Export format so its Import reads them back.
- `modules/wm/{hyprland,niri}/` — each has `session.nix` (NixOS: turns the WM on, login screen, keyring unlock) and `home/` (home-manager, everything else, including DankMaterialShell (DMS))
- `modules/theme/` — stylix, catppuccin, fonts, plus `gtk.nix` and `qt.nix`, the toolkit theming targets rule 5 routes through. No module sets the wallpaper: DMS picks it at runtime (`Mod+W`) and `theme/wallpapers/` holds the images
- `modules/nixos/security/vpn/mullvad/` — `daemon.nix` (daemon settings), `gui.nix` (tray app, a home-manager module) and `split-tunnel.nix` (system and home wrappers). Imported from `nixos/default.nix`, gated on `hostConfig.mullvad.enable`
- `hosts/{hostname}/` — `default.nix` (host entry), `settings.nix`, `hardware/` (`gpu.nix`, `hardware-configuration.nix`), `wm/<wm>.nix` (per-WM host overrides: GPU env vars, autostart, Hyprland monitors)
- `hosts/laptop/` also has `hardware/swapfile.nix` and `minecraft-servers/` (GTNH + TerraFirmaGreg server definitions, plus `mcservers.nix`, an fzf picker over them). `minecraft-servers/` is a **home-manager** module injected from `hosts/laptop/default.nix` via `home-manager.users.${username}.imports`, not a NixOS module, and the only place in the repo that reaches into HM from a host entry file.

### Where to place things

| Scope | Path |
| --- | --- |
| Shared system | `modules/nixos/` |
| Shared user | `modules/home/` |
| Per-host hardware/entry | `hosts/{hostname}/` |
| Per-host toggle | `hosts/{hostname}/settings.nix` |
| WM internals | `modules/wm/{wm}/` |
| Mullvad VPN | `modules/nixos/security/vpn/mullvad/` |
| Per-host WM overrides | `hosts/{hostname}/wm/{wm}.nix` (`hyprland.nix` / `niri.nix`) |

## Workflows

**Add an application** (the `add-app` skill runs these steps, then checks the wiring):
1. Add the toggle to **both** host configs (keep them symmetrical)
2. Create the module in the right subdir (`modules/home/programs/...`)
3. Add the conditional import to `modules/home/programs/default.nix`, the router under `programs/`; a `gaming.*` app goes in `programs/gaming/default.nix`, which routes its own launchers, games and tools, and a guitar app goes in `audio/guitar/default.nix`, with its toggle added to that folder's gate in `programs/default.nix`. The other nested `default.nix` files (`browsers/{zen,mullvad,helium}/`, `media/{freetube,moku}/`) are multi-file module bundles, not routers
4. `alejandra .` → `git add` new files → `nix flake check` (do not rebuild; hand it back)
5. Give any prose the task wrote or edited a cut-only revision pass before handing back: remove words, add none. No new information, no new claims, no rephrasing that smuggles either in. See **Writing Style**.
6. Add it to the matching `<details>` table under **Components** in `README.md` (plus `## Structure` for a new directory, `## Flake Inputs` for a new input), and its link-reference definition at the bottom: the README is the public-facing doc and drifts easily.

   Grep for the two regions, then edit those lines directly:

   ```bash
   grep -n '^| \*\*' README.md          # Components table rows
   grep -n '^\[.*\]: http' README.md    # link-reference block
   ```

   **Never add a `---` horizontal rule to `README.md`.** Zed's markdown preview
   pairs `---` lines across the whole file like front-matter delimiters, so every
   odd-numbered rule opens a raw block and the section after it renders as an
   unformatted code block (headings dead, so ToC anchors break; images shown as
   literal text). The file is still valid CommonMark and GitHub renders it fine,
   which makes this expensive to diagnose. Section breaks come from the `##`
   heading alone; GitHub already draws a rule under every H2. Verify markdown
   changes with `nix run nixpkgs#pulldown-cmark -- < README.md`, not the preview pane.

**Update FreeTube state** (blocklist or settings), asked for as "I blocked more" /
"sync freetube": the `freetube-sync` skill has the steps and checks; FreeTube stays closed
throughout. `~/.config/FreeTube/settings.db` is a NeDB append-log where a later line
with the same `_id` wins, so reduce it before reading:
`jq -rs 'reduce .[] as $x ({}; .[$x._id] = $x.value)' settings.db`. The blocklist sits
inside it as `channelsHidden`, a JSON **string** needing `fromjson`. A `nixm freetube-backup`
folder is restored through the app's Settings → Data Settings → Import, not by copying files
into place.

**Update flake inputs:** the user-only `flake-update` skill (`/flake-update [input…]`) does what `nixm upgrade` does, minus the rebuild. It builds this host without activating it, fixes or switches off failures and rechecks disabled packages, then hands back the rebuild command. Asked to update the flake, point the user at it.

**Add a system service:** same flow, but `modules/nixos/services/<category>/<name>.nix` and import in `modules/nixos/default.nix`.

**Switch WM:** change `windowManager` in the host's hostConfig, then hand back for the rebuild.

**Customize WM:** edit `modules/wm/{wm}/home/...` for shared behavior, or `hosts/{hostname}/wm/{wm}.nix` for per-host overrides (GPU env vars, Hyprland monitors). Niri's monitors for both hosts are in `niri/home/core/monitors.nix`, keyed on `hostname`.

## Window Managers

**Keybind syntax differs per WM, so never mix them.**

Hyprland uses the Lua config (`configType = "lua"`), so each bind is an `hl.bind` call built from `_args` with a Lua dispatcher. `modules/wm/hyprland/home/core/binds.nix` wraps that shape in two helpers, and new binds go through them:
```nix
(exec "SUPER + Return" "kitty")                                       # hl.dsp.exec_cmd("kitty")
(bind "SUPER + 0" ''hl.dsp.workspace.toggle_special("scratchpad")'')  # any other dispatcher
```

Window and layer rules stay in the `"match:class X, float on"` string form and go through `core/rules/luaRule.nix`. Check changes with the `hyprland-verify` skill, which builds a host's `hyprland.lua` (even while it runs niri) and runs `Hyprland --verify-config` on it.

Niri uses attribute-set actions, and **spawns with arguments must be lists**, not strings (`modules/wm/niri/home/core/binds.nix`):
```nix
programs.niri.settings.binds = {
  "Mod+Return".action.spawn = "kitty";                            # single command, string OK
  "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];      # args → must be a list
  "Mod+Left".action.focus-column-left = {};
};
```

A string like `"dms ipc call spotlight"` in Niri only runs `dms` and drops the rest, so use `["dms" "ipc" "call"] ++ lib.splitString " " action`. An assertion in `niri/home/core/binds.nix` fails the build on a `spawn` string containing a space.

**DMS** (DankMaterialShell): Niri and Hyprland only. Declarative config lives at `modules/wm/{wm}/home/shell/dms/`. Both have `default.nix`, `settings.json` and `clsettings.json`; Niri additionally has `niri-cheatsheet.json`. The DMS keybind helper differs per WM (an `hl.dsp.exec_cmd` Lua helper for Hyprland, list concat for Niri).

DMS runs as a systemd user service (`systemd.enable`, `niri.enableSpawn = false`), so it inherits the **systemd user manager** environment (`modules/home/variables.nix`), not niri's `programs.niri.settings.environment` block. It launches every app with `systemd-run --user --scope`, so those session variables, and not niri's, govern anything started from the spotlight. Keep the two sets compatible: `QT_QPA_PLATFORM` and `GDK_BACKEND` must keep their X11 fallbacks (`wayland;xcb`, `wayland,x11`) or X11-only apps die instantly from the launcher while still working from a terminal: a Qt app with no wayland plugin aborts in ~50 ms, a JUCE/GTK one exits with "cannot open display". Diagnose by diffing `tr '\0' '\n' < /proc/$(pgrep -x .quickshell-wra)/environ` against `env`, then replaying with `env -i "${DMS_ENV[@]}" <app>`. A rebuild alone does not fix a bad value: the running manager keeps the old import, so `systemctl --user set-environment` then restart `dms.service`, or log out.

**XDG portals** (Niri): `niri/session.nix` strips `GDK_BACKEND` from `xdg-desktop-portal-gnome`, and `niri/home/core/portals.nix` adds the gtk backend back. Read `docs/wm/niri-xdg-portals.md` before touching either, and never "fix" a portal by dropping the X11 fallback from `variables.nix`.

**Login:** Niri and Hyprland start from the DMS greeter (greetd, through the `dank-greeter` input, set up in `<wm>/session.nix`).

**Hyprland-only directories:** `core/animations.nix`, `core/layouts/`, `core/variables.nix`, `core/rules/` (`luaRule.nix`, `windowrules/`, `layerrules/`), `scripts/`.
**Niri-only directories:** `core/monitors.nix`, `core/portals.nix`, `core/rules.nix`, `core/xwayland.nix`, `addons/`.

Per-host WM overrides exist where needed:
- `hosts/laptop/wm/{hyprland,niri}.nix` — hybrid-GPU env (`WLR_DRM_DEVICES`), Solaar autostart; the niri one also turns off DMS auto-lock
- `hosts/desktop/wm/hyprland.nix` — monitor layout, workspace assignment (`desktop/wm/niri.nix` is an empty stub)

These are only imported when the WM is active, e.g. `lib.optional (hostConfig.windowManager == "niri") ./wm/niri.nix`.

## Hardware

**Desktop:** AMD-only (RX 9070 XT direct rendering), `sched_migration_cost_ns=5ms`, performance governor. Suspend is disabled because the RX 9070 XT doesn't resume cleanly.
**Laptop:** TLP power mgmt, hybrid GPU defaults to AMD 680M; route apps to RTX 4070 with `nvidia-offload <app>`. WM-specific GPU vars live in `hosts/laptop/wm/`. It doubles as the Minecraft server host, so sleep, suspend and hibernate are off, the lid and power key are ignored, and DMS auto-lock is off under niri.

## Network

- DNS: systemd-resolved (stub listener on 127.0.0.53, opportunistic DNS-over-TLS, no fallback servers) + NetworkManager
- WiFi: iwd, IPv6 privacy, random MAC
- Firewall: TCP 22 (open; sshd only runs when `hostConfig.ssh.enable` is set), 80, 443, 25566 (Minecraft), 7777 (Terraria), 5555 (ADB); UDP 27000–27009, 27015, 27031–27036 and 4380 (Steam). Defined in `modules/nixos/network/firewall.nix`. When `hostConfig.syncthing.enable` is set, the Syncthing module also opens TCP/UDP 22000 and UDP 21027.
- Mullvad: `hostConfig.mullvad.enable` (WireGuard, quantum resistance, multihop, DAITA; lockdown mode cuts all traffic while the tunnel is down), `modules/nixos/security/vpn/mullvad/`: `daemon.nix` (daemon settings), `gui.nix` (tray app) and `split-tunnel.nix`. Settings are applied with the `mullvad` CLI from a oneshot unit, not by templating `settings.json`, which the daemon rewrites. Relay and entry selection are deliberately unmanaged so exits can be switched by hand. `hostConfig.mullvad.splitTunnel` names apps routed around the VPN; `split-tunnel.nix` puts each wrapper in the profile its app is installed in, since the home profile outranks `/run/current-system/sw/bin` in PATH and a system wrapper for an HM package is silently shadowed.
- `network/blockers.nix` — hosts-level blocklists, always imported

## Security

LUKS, kernel hardening, AppArmor, GNOME Keyring, auditd. Mullvad VPN as above. Wheel needs a password for sudo, so `nixm rebuild` prompts once (in a zenity window when no terminal is attached, as with `! nixm rebuild` in Claude Code, through the `SUDO_ASKPASS` helper `nixm.nix` sets); the NOPASSWD list in `security/auth/sudo.nix` covers only sync, poweroff, reboot and shutdown. Keep it to commands that cannot be turned into a root shell (sed, systemctl, nixos-rebuild and dmesg all can).

Audit tooling is `lynis` (configuration) and `sbomnix`/`vulnxscan` (CVE scanning against the real closure, via osv.dev). **Do not go back to `vulnix`**: it only knows NVD's legacy JSON 1.1 feeds, which return 403 since their retirement, so every run ends in a `ConnectionError` traceback. Verified 2026-09-22, when the NVD API 2.0 answered 200 from the same machine.

**AppArmor profiles** live in `modules/nixos/security/apparmor/`, one module per app (`archives.nix` holds file-roller and unrar), gated on the app's hostConfig toggle where it has one, all in `complain` mode. Attach them by store-path glob (`/nix/store/*-mpv-*/bin/mpv`), never to a binary Nix builds also run (unzip, tar). `nix flake check` does not parse profiles, so test-compile them with the `apparmor-check` skill before handing back. Log reading, the enforce procedure and known gaps are in `docs/security/apparmor.md`.

`hostConfig.ssh.enable` gates `nixos/services/ssh.nix`, which owns both sshd and fail2ban: key-only auth, no root login, no forwarding, ed25519 host key, and the fail2ban sshd jail. An assertion refuses to build when the toggle is on and `authorizedKeys.keys` in that module is empty, since password and keyboard-interactive auth are both off and there would be no way in.

## Writing Style

Covers everything with prose in it: chat replies, `README.md`, `docs/`, commit
messages. Code comments have their own rules under **Comment Style** below.

**Avoid the usual LLM tells.** They are what makes a reader decide a text was
machine-written:

- **"It's not X, it's Y."** Same for "not just X, but Y" and "X isn't about A,
  it's about B". State the point once, directly.
- **Fragments used for emphasis.** "Every time." "No exceptions." "Silently."
  Write them as part of a sentence.
- **Stacked short sentences.** Three or four clipped sentences in a row read
  as machine-written even when each one is grammatical. Join them with a
  comma or a semicolon and let the paragraph run at an uneven length.
- **Upbeat filler.** No "Great question", "Perfect!", "Happy to help", no
  exclamation marks, no closing line congratulating the work ("Your config is
  now fully modular!").
- **Affirming the user before answering.** Drop "You're absolutely right" and
  the restatement of what was just asked. Start with the answer.
- **Hedging boilerplate.** "It's worth noting", "It's important to understand",
  "Keep in mind". Say the caveat or leave it out.
- **Rule-of-three everything.** Three bullets, three adjectives, three parallel
  clauses. If there are two real items, list two.
- **Rigid parallel bullets** that all open with the same word and run the same
  length. Vary them, or use prose.
- **Abstract marketing nouns** where a plain phrase works: "Easy undo" beats
  "Declarative rollback capability". Superlatives belong in the same bin:
  cutting-edge, revolutionary, world-class, best-in-class, acclaimed.
- **Puffery.** How important a thing is, how significant the change was, and
  how well it works are the reader's call, not the writer's. "Stylix ensures
  a consistent look across every application" fails this even though every
  word in it is allowed; "Stylix sets the palette" is the fix. Say what the
  thing does and stop there. This one is about the move, not the vocabulary,
  so a sentence can fail it while passing every word list above.
- **False ranges and empty summary sentences.** "From keybinds to portals,
  the WM modules cover the full desktop experience" gestures at breadth
  without naming anything inside it. If a sentence would survive deletion
  with no information lost, delete it.
- **Pet words.** The LLM favourites: delve, robust, seamless, leverage,
  crucial, ensure, comprehensive, streamline, elegant, powerful, versatile,
  utilize, showcase, intricate, landscape, realm, essentially, furthermore,
  tapestry, testament, underscore, pivotal, foster, enhance. The "stands as"
  construction goes with them ("this stands as a testament to"). Also any
  word leaned on twice in a short passage, even a harmless one. Reach for the
  plain synonym, or cut the word.

What to do instead: use contractions, vary sentence length, and vary the
subject, since consecutive sentences opening the same way read stiff. Plain
words over jargon. In `README.md` and `docs/` prose also skip em dashes; a
colon, a comma, parentheses, or two sentences all work. This applies to dashes
inside a sentence. A dash separating a label from its description in a list
(`` `path/` — what it holds ``) is structure, not prose, and stays.

Structure is not the problem and should stay. The bold-label bullet listing
(`**Short label:** description`) is the house style for `README.md` and stays
even when the wording around it gets loosened up.

`docs/` carries three extra rules, because a note is read months later with
no memory of writing it. Pin anything time-bound to an absolute date or
version rather than "recently", "currently" or "the latest version". Replace a
vague frequency ("sometimes crashes") with the condition that triggers it. Say
where a claim came from, an issue number, a commit, a man page, instead of
asserting that something is known to break.

These rules cover prose only. Leave code blocks, command output, quotes, and
table cells alone: repetition in a keybind or command table is the column
doing its job, not a tell.

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
nix flake check                  # Syntax (fastest)
nixm rebuild --show-trace        # Full trace (ask the user to run this)
journalctl -xeu <service>        # Service logs
journalctl -b -p err             # Errors this boot
```

Common errors:
- `infinite recursion` → circular import or self-referencing conditional
- `attribute missing` → option not declared in the active host's hostConfig
- Slow / hung → check `df -h`; try `nix build --offline`

**Rollback:** `sudo nixos-rebuild switch --rollback`, or pick a generation from the bootloader.

**Laptop GPU:** `lspci | grep -i vga`, `env | grep -E 'DRI|VDPAU|LIBVA|VK'`. Configs: `hosts/laptop/hardware/gpu.nix` and `hosts/laptop/wm/{hyprland,niri}.nix`. Verify offload with `nvidia-offload glxinfo | grep "OpenGL renderer"`.

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

Security/privacy notes live under `docs/security/`:

- `security/blocklists.md` — uBlock Origin filter lists
- `security/ublock-filters.md` — custom uBlock cosmetic filters (paste into uBlock → My Filters)
- `security/android-quic-vpn-leak.md` — QUIC VPN bypass (CVE, May 2026): mitigation via `adb shell device_config put tethering close_quic_connection -1`; re-apply after Android updates
- `security/apparmor.md` — the per-app AppArmor profiles: what each attaches to, reading `apparmor="ALLOWED"` log lines, moving a profile to enforce, and what breaks first when you do

Game-specific notes live under `docs/gaming/`:

- `gaming/tmodloader-debugging.md` — tModLoader paths and log locations
- `gaming/steam-launch-parameters.md` — per-game Steam launch flags; documents the `tml-prelaunch` script (`modules/home/programs/gaming/scripts/tml-prelaunch.nix`)
- `gaming/launcher-env-variables.md` — common env vars + wrappers for Heroic/Lutris/Faugus/umu/Steam (JP locale, Proton WineD3D, XWayland wrapper, RPG Maker, perf wrappers)
- `gaming/steam-client-menu-bug.md` — Steam's menus self-dismiss on niri because xwayland-satellite 0.8.2 focuses override-redirect windows; fixed in v0.8.3 (upstream `add2795`, PR #494), which nixpkgs ships, so `niri/home/core/xwayland.nix` uses the nixpkgs build again
- `gaming/rocksmith-2014.md` — Rocksmith 2014 on Proton 11 + WOW64 with the Katana DI via PipeASIO and RS_ASIO: the manual install steps the `gaming.rocksmith` module can't do, the Katana driver-priority stall, why calibration is skipped, which CDLC enabler build works (the CustomsForge v4.0 one, not the newer GitHub build), and the optional RSMods setup
- `gaming/minecraft_servers/{GTNH,TerraFirmaGreg-Modern}/` — each pack has `index.md` listing its sub-files (server setup, mods, config tweaks, etc.). **Update the relevant sub-file when that pack's config, mods, or settings change.** The matching declarative modules live at `hosts/laptop/minecraft-servers/{gtnh-server,tfg-server}.nix` (add a new server by creating a `.nix` there, importing it in that dir's `default.nix`, and adding a line to the hardcoded pack list in `mcservers.nix`, the fzf picker that names each pack with its version and dispatches to that server's command).

Android device notes live under `docs/android/`:

- `android/debloat/Lenovo-Idea-Tab-Pro/` — `index.md` (full redo procedure: never-remove list, install-replacements-first ordering, PMS flush, reboot test, privacy settings) + `removal-list.txt` (the 131 verified-safe packages). **A ZUI OTA restores every stock package, so this gets redone after each system update** with the `android-debloat-redo` skill.

Local (non-nixpkgs) binary installs live under `docs/local/`:

- `local/local-binary-installs.md` — the `~/.local/opt` wrapper pattern for prebuilt third-party bundles kept out of git; restore steps for fresh installs / the laptop. **Add an entry here for each new local app.**
- `local/appimage-wraps.md` — the `appimageTools.wrapType2` pattern for upstream AppImages. Hash-pinned into the store, so nothing to restore by hand; covers the per-app `Exec`/icon fixups, a non-executable `AppRun`, a DwarFS payload `appimageTools.extract` can't open (unpack with `dwarfsextract`), how to get a new hash when `nix store prefetch-file` hits the daemon's DNS timeout, and building one module without a rebuild.

nixpkgs update notes live under `docs/nixpkgs/`:

- `nixpkgs/disabled-packages.md` — packages switched off because a flake update broke them, with the date, the nixpkgs rev and how to tell a fix has landed. **Add a row whenever an update forces a package off, and remove it on re-enable.** The `disable-package` skill does both.

Window manager notes live under `docs/wm/`:

- `wm/niri-xdg-portals.md` — why `xdg-desktop-portal-gnome` drops to Settings-only when `GDK_BACKEND` is set, how niri-flake hides the system portal backends, and the `busctl` health check

Planned work lives under `docs/todo/`, one file per task, named after it (`todo/affinity-setup.md`). **When the user says "add X to the todo", write a new file there** holding what the task is, why they want it, what the repo already has toward it, the steps left, and any research already done (links, versions, gotchas). Update the file rather than starting a second one for the same task, and delete it once the work is done. These are working notes: no `README.md` or Components entry.
