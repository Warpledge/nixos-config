# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

NixOS flake managing **Desktop** (Ryzen 5800X3D + RX 9070 XT, 280Hz OLED + 144Hz) and **Laptop** (Legion Slim 5, Ryzen 7735HS + hybrid AMD 680M/RTX 4070, 1600p@165Hz). Nixpkgs unstable, Catppuccin Mocha Mauve via Stylix. Active WM: Niri; Hyprland, GNOME, and COSMIC modules also exist (Niri and Hyprland are the fully built-out ones).

## Critical Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead. Validation you SHOULD run yourself before reporting done: `alejandra .` → `git add <new files>` → `nix flake check`. The user handles all git operations.
2. **`git add` new files before `nix flake check`** — the flake won't see untracked files.
3. **Use surgical edits** (exact `old_string` → `new_string`), never rewrite whole files.
4. **Public repo:** no passwords, API keys, tokens, or secrets.
5. **Stylix owns theming.** Never set colors, fonts, or wallpaper in a module — enable the program's theming target and let Stylix supply the palette. Hardcoded values conflict with or silently override the theme.
6. **Set only what was asked for.** No extra options, defaults, or "nice to have" settings beyond the request.

`AGENTS.md` at the repo root is a second, shorter ruleset for other agents (opencode reads it *instead of* `CLAUDE.md`). The two must not contradict each other — when a rule here changes, check whether `AGENTS.md` says the same.

## Commands

```bash
nix flake check         # Validate syntax (run first, fastest feedback)
alejandra .             # Format all Nix files (v3.0.0 is the standard)
deadnix --no-lambda-arg # Find unused function arguments in Nix files
statix check .          # Lint for Nix antipatterns (inherit, empty patterns, etc.)
nixm lint               # Run both deadnix and statix in one shot (wraps the above two)
nixm rebuild            # Apply config (wraps `nh os switch`)
nixm rebuild 2>&1 | grep -E "error|Error|failed|Failed" || echo "✓"  # token-light rebuild
nixm upgrade            # Update flake inputs + rebuild
nixm flake-update       # Update flake inputs only (no rebuild)
nixm dryrun             # Rebuild without applying
nixm gc                 # GC, keep last 5 generations
nixm rollback           # Roll back to the previous generation
nixm freetube-sync      # Capture FreeTube subscriptions into subscriptions.nix (y/N prompt)
nixm vpn-list           # Show the Android VPN lockdown allowlist on an adb device
nixm vpn-edit           # Edit that allowlist in $EDITOR (applies on device reboot)
nix flake lock --update-input <name>   # Bump a single input
run <pkg> [args]        # Ad-hoc launch a nixpkgs package without installing it (zsh function)
```

`nixm` is an fzf-driven menu defined in `shared/modules/home-manager/scripts/nixm.nix` (aliased to `n`). Run `nixm <bogus>` to print the full subcommand list.

## Architecture

```
flake.nix
  → hosts/{hostname}/{hostname}.nix          (host entry)
    → hosts/{hostname}/hostConfig/core.nix   (toggles, passed as specialArgs)
    → shared/core.nix                        (NixOS + home-manager wiring)
      → shared/modules/{nixos,home-manager}/ (modular configs)
      → shared/modules/wm/${windowManager}/  (active WM only)
      → shared/modules/mullvad/            (both trees, if mullvad.enable)
```

`hostConfig` from each host's `hostConfig/core.nix` is threaded through `specialArgs`, so every module can read it. Conditional imports in each subdir's `default.nix` decide what loads.

### hostConfig

The authoritative list of toggles is **`hosts/{hostname}/hostConfig/core.nix`** — read it directly, don't trust this file to stay in sync. Current shape (desktop and laptop are kept symmetrical):

- `username` — read by `flake.nix` itself (`inherit (hostConfig) username`), not just by modules
- `windowManager` — `"hyprland" | "niri" | "gnome" | "cosmic"`
- `kernel` — `"zen" | "latest" | "xanmod" | "cachyos"`
- Service toggles: `mullvad.enable` (plus `mullvad.splitTunnel`, a list of command names routed around the VPN), `clamav.enable`, `docker.enable`, `winboat.enable`, `sunshine.enable`, `discord.arrpc.enable`, `scrcpy.enable`, `ferdium.enable`, `waydroid.{enable,magisk,nftables}`
- Attribute-set toggles: `browsers.{zen,mullvad,helium}`, `terminals.{kitty,ghostty}`, `editors.{helix,zed}`, `fileBrowsers.{nautilus,yazi}`, `media.{mpv,spotify,freetube,videoTrimmer,qrScanner}`, `graphics.{blender,krita,affinity}`, `audio.{reaper,guitar}`, `finance.{homebank}`, `gameLaunchers.{steam,heroic,prismlauncher,lutris,faugus,twintail}`, `japanese.{ime,vn}`
- `local.{granblueRelinkMods}` — wrappers around prebuilt bundles under `~/.local/opt/` (kept out of git); see `.notes/local/local-binary-installs.md`
- AI tools: `claude.enable`, `opencode.enable`, `lmstudio.enable`

Desktop and laptop should stay byte-identical apart from the header comment and a short list of deliberate differences. As of 2026-09-12 those are `waydroid.enable`, `gameLaunchers.heroic` and `discord.arrpc.enable`, all true on desktop and false on laptop (plus a longer trailing comment on `local.granblueRelinkMods` in the laptop file). Verify with `diff hosts/desktop/hostConfig/core.nix hosts/laptop/hostConfig/core.nix` before assuming.

Gotchas — grep the option name before assuming which file owns it:

- `fileBrowsers.nautilus` is a **dead toggle**: `nautilus.nix` is imported unconditionally in `programs/default.nix`. Only `fileBrowsers.yazi` is actually read.
- `gameLaunchers.steam` / `.twintail` are wired in `shared/modules/nixos/programs/gaming/core.nix`; `heroic`, `prismlauncher`, `lutris`, `faugus` are wired in `home-manager/programs/default.nix`.
- The Katana patch editor is a `~/.local/opt` bundle but does **not** live in `programs/local/` — it moved into `creative/guitar.nix` with the rest of the amp rig, so it has no `local.*` toggle of its own and rides on `audio.guitar`.
- `docker.enable` does **not** use a conditional import — `nixos/default.nix` imports `programs/docker.nix` unconditionally and the module wraps its whole body in `config = lib.mkIf hostConfig.docker.enable {...}`. Both patterns exist in the repo; prefer the conditional import for new modules.
- Module *loading* goes through `lib.optionals` in a `default.nix`; config *logic* inside a module uses `if/then/else`. Mixing them up is why an option looks wired but has no effect.
- Reach nested attrs that may not exist with `hostConfig.feature.sub or false`, never a bare path.

### Conditional import patterns

```nix
# Single boolean
++ lib.optionals hostConfig.clamav.enable [./services/clamav.nix]

# Attribute-set item
++ lib.optionals hostConfig.browsers.zen [./browsers/zen]
++ lib.optionals hostConfig.media.mpv [./media/mpv.nix]

# WM module selection (in shared/core.nix) — the WM is split across both trees
# NixOS imports:
./modules/wm/${hostConfig.windowManager}/${hostConfig.windowManager}-nixos
# home-manager imports:
./modules/wm/${hostConfig.windowManager}/${hostConfig.windowManager}-home

# Per-host WM override (in hosts/{hostname}/{hostname}.nix)
++ (lib.optional (hostConfig.windowManager == "niri") ./wm/niri.nix)
```

`shared/core.nix` is also where the CachyOS kernel overlay is conditionally applied (`hostConfig.kernel == "cachyos"` → `inputs.cachyos-kernel.overlays.pinned`), where `nixpkgs.config.allowUnfree` is set, and where `home-manager.backupFileExtension = "bak"` is set. Both `system.stateVersion` and `home.stateVersion` are pinned to `25.11` — marked DO NOT CHANGE.

### Module layout

- `shared/modules/nixos/` — system: `network/`, `nix/`, `security/`, `services/`, `programs/` (incl. `gaming/`, `flatpak.nix`), `system/` (bootloader, locale, user, wayland, zram, japanese-ime)
- `shared/modules/home-manager/` — user: `programs/` (browsers, terminals, editors, ai, shell, chat-clients, emulation, fetch, file-browsers, creative, media, finance, launchers, local, plus `android.nix`, `archives.nix`, `gaming.nix`, `git.nix`, `japanese-vn.nix`), services, scripts, mime, variables
  - `programs/local/` — wrappers for non-nixpkgs prebuilt bundles living in `~/.local/opt/`; the payload is intentionally not in the repo
  - `default.nix` carries a `clearStaleBackups` activation hook that deletes `*.bak` under `~/.config`, `~/.local/{share,state}` before `checkLinkTargets`. This is why HM activation never fails on leftover backups — don't remove it when debugging a "file exists" error; find the real conflicting file instead.
  - `programs/media/freetube/` — `settings.nix` (mirrored from the app), `blocked-channels.nix` (~2k channel ids in one flat list, sorted by lowercased name under `LC_ALL=C`) and `subscriptions.nix` (master list + FreeTube profiles, which are subscription groups). Three things bite here. The home-manager module copies `hm_settings.db` over `settings.db` **only when the declared content changes**, and FreeTube rewrites that file from memory when it exits — so close FreeTube before rebuilding, or the copy is clobbered and stays clobbered until the module changes again. Blocklist entries are emitted with a `preferredName` and a placeholder `icon`, because FreeTube re-resolves every entry missing either one, at one API call each. Ownership differs per file: settings and the blocklist are **mirrored** (module wins, a rebuild copies them in), while subscriptions and profiles are **seed-only** — a `home.activation` script guarded by `[[ ! -e ]]` writes `profiles.db` once, so the app owns them and rebuilds never overwrite. `nixm freetube-sync` recaptures subscriptions behind a y/N prompt, but not profiles.
- `shared/modules/wm/{hyprland,niri,gnome,cosmic}/` — each has `<wm>-nixos/` and `<wm>-home/`. Only Hyprland and Niri integrate DankMaterialShell (DMS); GNOME uses `gnome-home/extensions/` + `dconf.nix`, COSMIC uses `cosmic-home/shell/{panel,applets}.nix`
- `shared/modules/theme/` — stylix, catppuccin, fonts
- `shared/modules/mullvad/` — `mullvad-nixos/` (daemon settings + system-package split tunnel) and `mullvad-home/` (tray app + home-package split tunnel). Imported from `shared/core.nix` like the WM, gated on `hostConfig.mullvad.enable`
- `hosts/{hostname}/` — `gpu.nix`, `hardware-configuration.nix`, `{hostname}.nix`, `hostConfig/core.nix`, `wm/<wm>.nix` (per-WM host overrides: monitors, GPU env vars, autostart)
- `hosts/laptop/` also has `swapfile.nix` and `minecraft-servers/` (GTNH + TerraFirmaGreg server definitions). `minecraft-servers/` is a **home-manager** module injected from `laptop.nix` via `home-manager.users.${username}.imports`, not a NixOS module — the only place in the repo that reaches into HM from a host entry file.

### Where to place things

| Scope | Path |
| --- | --- |
| Shared system | `shared/modules/nixos/` |
| Shared user | `shared/modules/home-manager/` |
| Per-host hardware/entry | `hosts/{hostname}/` |
| Per-host toggle | `hosts/{hostname}/hostConfig/core.nix` |
| WM internals | `shared/modules/wm/{wm}/` |
| Mullvad VPN | `shared/modules/mullvad/{mullvad-nixos,mullvad-home}/` |
| Per-host WM overrides | `hosts/{hostname}/wm/{wm}.nix` (only `hyprland.nix` / `niri.nix` exist; GNOME and COSMIC have no host overrides) |

## Workflows

**Add an application:**
1. Add the toggle to **both** host configs (keep them symmetrical)
2. Create the module in the right subdir (`shared/modules/home-manager/programs/...`)
3. Add the conditional import to `shared/modules/home-manager/programs/default.nix` — the only router under `programs/`. The nested `default.nix` files (`browsers/{zen,mullvad,helium}/`, `media/freetube/`) are multi-file module bundles, not routers
4. `alejandra .` → `git add` new files → `nix flake check` (do not rebuild; hand it back)
5. Add it to the matching `### ` list under **Components** in `README.md` (and `## Structure` if a new directory was created), plus its link-reference definition at the bottom — the README is the public-facing doc and drifts easily.

   **`README.md` is ~25 KB — never read it in full.** Grep the two regions you need, then edit those lines directly:

   ```bash
   grep -n '^| \*\*' README.md          # Components table rows
   grep -n '^\[.*\]: http' README.md    # link-reference block
   ```

**Update FreeTube state** (blocklist, settings, subscriptions, profiles) — asked for as
"I blocked more" / "I added subscriptions" / "sync freetube":

1. **Close FreeTube first.** Both `~/.config/FreeTube/settings.db` and `profiles.db` are
   rewritten from memory on exit, so a capture taken while it runs is stale, and a rebuild
   while it runs gets clobbered.
2. **Both files are NeDB append-logs** — later lines supersede earlier ones with the same
   `_id`. Always reduce before reading:
   `jq -rs 'reduce .[] as $x ({}; .[$x._id] = $x.value)' settings.db`
   `jq -rs 'reduce .[] as $p ({}; .[$p._id] = $p)' profiles.db`
   The blocklist lives inside settings as `channelsHidden`, a JSON **string** needing `fromjson`.
3. **Blocklist** — diff live ids against `(mk "…"` in the module, emit new ones as
   `(mk "UC…" "Name")`, then re-sort the whole list by lowercased name under `LC_ALL=C`.
4. **Subscriptions and profiles** — regenerate both blocks wholesale from `profiles.db`.
   Groups use `pick [ids]` so names and thumbnails come from the master list.
5. **Validate**: entry count, no duplicate ids, id set unchanged except the intended delta,
   and every entry still has a non-empty `preferredName` + `icon`.
6. `alejandra .` → `nix flake check`, then hand back for the rebuild — app still closed.

Profiles are seed-only, so a rebuild will **not** push module-side group changes into the
app. To apply those: `install -Dm644 ~/.config/FreeTube/hm_profiles.db ~/.config/FreeTube/profiles.db`
with the app closed, after the rebuild has refreshed the store file.

**Add a system service:** same flow, but `shared/modules/nixos/services/<name>.nix` and import in `shared/modules/nixos/default.nix`.

**Switch WM:** change `windowManager` in the host's hostConfig, then hand back for the rebuild.

**Customize WM:** edit `shared/modules/wm/{wm}/{wm}-home/...` for shared behavior, or `hosts/{hostname}/wm/{wm}.nix` for per-host overrides (monitors, GPU env vars).

## Window Managers

**Keybind syntax differs per WM — never mix.**

Hyprland uses string dispatch (`shared/modules/wm/hyprland/hyprland-home/core/binds.nix`):
```nix
bind = [ "$mainMod, Return, exec, kitty" ];
```

Niri uses attribute-set actions, and **spawns with arguments must be lists**, not strings (`shared/modules/wm/niri/niri-home/core/binds.nix`):
```nix
programs.niri.settings.binds = {
  "Mod+Return".action.spawn = "kitty";                            # single command, string OK
  "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];      # args → must be a list
  "Mod+Left".action.focus-column-left = {};
};
```

A string like `"dms ipc call spotlight"` in Niri only runs `dms` and drops the rest — use `["dms" "ipc" "call"] ++ lib.splitString " " action`.

COSMIC is the opposite of Niri: `Spawn` is a **single string** run through `/bin/sh -c`, so arguments and shell syntax belong inline and must *not* be split into a list (`shared/modules/wm/cosmic/cosmic-home/core/binds.nix`):
```nix
{key = "Super+Shift+W"; action = arg "Spawn" "waydroid session start";}   # one string
{key = "Super+F";       action = plain "Maximize";}                       # nullary enum
{key = "Super+Tab";     action = enumArg "System" "WorkspaceOverview";}   # nested enum
```

GNOME defines no keybinds of its own beyond dconf — it is a light-weight fallback, not a peer of Niri/Hyprland/COSMIC.

**DMS** (DankMaterialShell): Niri and Hyprland only. Declarative config lives at `shared/modules/wm/{wm}/{wm}-home/shell/dms/` — Hyprland has `core.nix` + `settings.json`; Niri additionally has `clsettings.json` and `niri-cheatsheet.json`. The DMS keybind helper differs per WM (string interpolation for Hyprland, list concat for Niri).

DMS runs as a systemd user service (`systemd.enable`, `niri.enableSpawn = false`), so it inherits the **systemd user manager** environment — `shared/modules/home-manager/variables.nix` — not niri's `programs.niri.settings.environment` block. It launches every app with `systemd-run --user --scope`, so those session variables, and not niri's, govern anything started from the spotlight. Keep the two sets compatible: `QT_QPA_PLATFORM` and `GDK_BACKEND` must keep their X11 fallbacks (`wayland;xcb`, `wayland,x11`) or X11-only apps die instantly from the launcher while still working from a terminal — a Qt app with no wayland plugin aborts in ~50 ms, a JUCE/GTK one exits with "cannot open display". Diagnose by diffing `tr '\0' '\n' < /proc/$(pgrep -x .quickshell-wra)/environ` against `env`, then replaying with `env -i "${DMS_ENV[@]}" <app>`. A rebuild alone does not fix a bad value: the running manager keeps the old import, so `systemctl --user set-environment` then restart `dms.service`, or log out.

**XDG portals** (Niri): `xdg-desktop-portal-gnome` exposes **only** `org.freedesktop.impl.portal.Settings` — instead of its usual 15 interfaces — whenever `GDK_BACKEND` is set in its environment, at any value, including the `wayland,x11` fallback above. It logs `GDK backend forced via env var` then `Non-compatible display server, exposing settings only.`, and every interface routed to it dies: FileChooser (a browser's "Save image as" opens no dialog at all) and ScreenCast (screen sharing). Not version-specific — 49.0 and 50.0 both. `niri-nixos/default.nix` strips the variable with a systemd user drop-in (`overrideStrategy = "asDropin"`, `serviceConfig.UnsetEnvironment`); do **not** "fix" it by dropping the X11 fallback from `variables.nix`, which breaks X11-only apps as described above.

There is no runtime fallback between backends: xdg-desktop-portal picks one from the `.portal` file's `Interfaces=` list, and `gnome.portal` advertises FileChooser regardless of what the process actually exports, so `default=gnome;gtk` never reaches gtk. Separately, niri-flake's **home** module sets `xdg.portal.extraPortals = [xdg-desktop-portal-gnome]`, which repoints `NIX_XDG_DESKTOP_PORTAL_DIR` at `/etc/profiles/per-user/$USER/share/xdg-desktop-portal/portals` holding only `gnome.portal` — the system-wide backends go invisible and the `Access`, `Notification` and `Secret` routes in `niri-portals.conf` cannot resolve. `niri-home/core/portals.nix` adds gtk back; `Secret` is still unrouted because `gnome-keyring` would pull the whole package into the user profile. Check health with `busctl --user introspect org.freedesktop.impl.portal.desktop.gnome /org/freedesktop/portal/desktop | grep -c ^org.freedesktop.impl` — 1 is broken, 15 is healthy.

**cosmic-manager** (COSMIC): nixpkgs ships no home-manager options for COSMIC, so the `wayland.desktopManager.cosmic.*` surface comes from the `cosmic-manager` flake input, imported in `cosmic-home/default.nix`. Two things make it behave unlike the rest of the repo:

- **It does not symlink.** It renders the options to a JSON manifest and runs `cosmic-ctl apply` from a HM activation script, so `~/.config/cosmic/<component>/v1/<key>` stays a real writable file and COSMIC Settings keeps working. Declared keys are rewritten each activation; undeclared keys are never touched. Do **not** go back to `xdg.configFile` + `force = true` for COSMIC — that is what made the Settings GUI read-only before.
- **Never put `$` in a COSMIC `Spawn` string.** cosmic-manager serializes RON with `lib.strings.escapeNixString`, which emits `\$`. RON only accepts `\' \" \\ \n \r \t \0 \x \u`, so the `ron` parser rejects the whole file and **every** custom shortcut silently dies. Put command substitutions in a `writeShellScriptBin` and spawn that instead — `core/binds.nix` does this for the screen-recorder binds. Re-test if the input is ever bumped.

`panels` is authoritative over `com.system76.CosmicPanel/v1/entries`: a panel omitted from the list is deleted. Only `Panel` is declared, so COSMIC's default Dock is removed — this mirrors the DMS bar, which runs with `showDock = false`. `name` and `margin` are the only non-nullable panel options, so a placeholder panel still needs both.

**Third-party applets** (minimon, privacy indicator, caffeine) have no typed cosmic-manager module — they are plain cosmic-config components reachable through the generic `wayland.desktopManager.cosmic.configFile."<app-id>"` escape hatch. A Rust struct deriving `CosmicConfigEntry` writes **one file per field**, and a struct marked `#[serde(default)]` accepts a **partial** value. Three traps, all hit in practice:

- **The component ID can depend on where the applet is hosted.** minimon in the panel reads `io.github.cosmic_utils.minimon-applet-panel`; the un-suffixed `io.github.cosmic_utils.minimon-applet` is the dock/standalone instance. Declaring the wrong one writes a config dir nothing reads and fails silently. Always check `ls -d ~/.config/cosmic/*<applet>*` before declaring.
- **Partial structs reset what they omit.** Fine for a struct you fully own, destructive for one tuned in a GUI — minimon persists ~3.7 KB per sensor including all colour fields. To capture GUI-tuned state, commit the RON and feed it back with `{__type = "raw"; value = builtins.readFile ./file.ron;}` rather than transcribing fields.
- **Hardware-keyed maps never port.** minimon's `gpus` is keyed per GPU, so it cannot be shared between desktop and laptop.

When a schema is undocumented, tune it once in the GUI and run `cosmic-ctl backup <out.json>` to dump the exact RON rather than guessing.

The COSMIC panel is a deliberate port of the DMS "Main Bar" in `niri-home/shell/dms/settings.json` (`barConfigs[0]`) — widget order, anchor, opacity and output all trace back to it, and `shell/panel.nix` annotates each applet with the DMS widget it stands in for. **Rearranging either bar means updating the other.** Verify an applet ID before adding it: `ls $(nix build --no-link --print-out-paths nixpkgs#cosmic-applets)/share/applications`.

**Hyprland-only directories:** `core/animations.nix`, `core/variables.nix`, `core/rules/{windowrules,layerrules}/`, `scripts/`.
**Niri-only directories:** `core/monitors.nix`, `core/rules.nix`, `core/xwayland.nix`, `addons/`.
**COSMIC-only files:** `core/settings.nix` (compositor + the cosmic-manager master toggle), `core/binds.nix`, `core/mime.nix`.

Per-host WM overrides exist where needed:
- `hosts/laptop/wm/{hyprland,niri}.nix` — hybrid-GPU env (`WLR_DRM_DEVICES`), monitor, Solaar autostart
- `hosts/desktop/wm/{hyprland,niri}.nix` — monitor layout, workspace assignment

These are only imported when the WM is active, e.g. `lib.optional (hostConfig.windowManager == "niri") ./wm/niri.nix`.

## Hardware

**Desktop:** AMD-only (RX 9070 XT direct rendering), `sched_migration_cost_ns=5ms`, performance governor, cachyos kernel.
**Laptop:** TLP power mgmt, hybrid GPU defaults to AMD 680M; route apps to RTX 4070 with `nvidia-offload <app>`. WM-specific GPU vars live in `hosts/laptop/wm/`.

## Network

- DNS: systemd-resolved + NetworkManager (DNSStubListener disabled so port 53 is free)
- WiFi: iwd, IPv6 privacy, random MAC
- Firewall: TCP 22 (port reserved, `services.openssh` off), 80, 443, 25566 (Minecraft), 7777 (Terraria), 5555 (ADB); UDP 27000–27036 range (Steam). Defined in `shared/modules/nixos/network/core.nix`.
- Mullvad: `hostConfig.mullvad.enable` (WireGuard + quantum resistance), `shared/modules/mullvad/` — split across `mullvad-nixos/` (daemon settings, split tunnel) and `mullvad-home/` (tray app). Settings are applied with the `mullvad` CLI from a oneshot unit, not by templating `settings.json`, which the daemon rewrites. Relay and entry selection are deliberately unmanaged so exits can be switched by hand. `hostConfig.mullvad.splitTunnel` names apps routed around the VPN; the NixOS half wraps system packages, the home half wraps `home.packages` ones — the home profile outranks `/run/current-system/sw/bin` in PATH, so a NixOS wrapper for an HM package is silently shadowed.
- `network/blockers.nix` — hosts-level blocklists, always imported

## Security

LUKS, kernel hardening, AppArmor, GNOME Keyring, auditd. Mullvad VPN as above.

## Formatting Standards

Alejandra (v3.0.0) is the formatter. Header hierarchy used throughout the repo:

- **L1** — `#====...====#` then `# FILE PURPOSE (UPPERCASE)`, one file-purpose header per file
- **L2** — `#----...----#` then `#-- Section Name` (title case, no closing rule)
- **L3** — `#--- Item description`
- **L4** — inline `# comment` (explain *why*, not *what*)

Spacing: 1 blank line before each header level, 1 after L1, none between L3 items, 1 after closing braces. Alejandra collapses multiple blank lines to one.

When reformatting an existing file: add headers, normalize spacing, convert inline markers to the hierarchy above. **Never delete content** — including commented-out code and disabled options.

### Comment Style

**Keep comments short. A comment earns its place by saving the next reader a trip to the docs — not by narrating.** One or two lines is normal; a paragraph is a smell.

Write comments for someone reading this file cold in six months:

- **Do** name what a non-obvious option or value does, flag a constraint the type system won't catch (`margin` must be 0 when `anchor_gap` is false), and point at where a value came from when it must be kept in sync.
- **Don't** write session narrative — how a bug was found, what was tried first, what "we" discovered, or which approach got rejected. If a gotcha is worth keeping, it goes in CLAUDE.md once, and the module gets a one-line pointer.
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

**Laptop GPU:** `lspci | grep -i vga`, `env | grep -E 'DRI|VDPAU|LIBVA|VK'`. Configs: `hosts/laptop/gpu.nix` and `hosts/laptop/wm/{hyprland,niri}.nix`. Verify offload with `nvidia-offload glxinfo | grep "OpenGL renderer"`.

## Looking things up

**Never write a package homepage, description, or option name from memory.**

| Need | Use |
| --- | --- |
| Package metadata | `nix eval --raw nixpkgs#<pkg>.meta.homepage` |
| nixpkgs packages / NixOS + home-manager options | the **nixos-mcp** tool (over `nix search` or scraping `search.nixos.org`) |
| Library / SDK / API docs | the **context7** tool (over web search) |
| An app's own config syntax | `nix-shell -p <pkg> --run 'man <name>'` |

**Check for a home-manager module before falling back to `home.packages`.** Many programs have one and it is the better module:

```bash
find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix' | head -1
```

If that returns a path, read it and use `programs.<pkg>` instead.

**Filter at the source.** Man pages, store listings, and long files go through `grep`/`sed` — never dump one into the conversation. Target the path you want rather than listing a directory, and if you need several sections of the same document, dump it once to a file and grep that.

**Stop once you have the answer.** A package's own man page is authoritative for its config syntax; don't go on to read the nixpkgs derivation or build inputs, which describe how it is built, not how it is configured. Don't guess documentation URLs — if two web fetches fail, fall back to a local source.

## Reference Notes (`.notes/`)

Security/privacy notes live under `.notes/security/`:

- `security/blocklists.md` — uBlock Origin and AdGuard Home filter lists
- `security/ublock-filters.md` — custom uBlock cosmetic filters (paste into uBlock → My Filters)
- `security/android-quic-vpn-leak.md` — QUIC VPN bypass (CVE, May 2026): mitigation via `adb shell device_config put tethering close_quic_connection -1`; re-apply after Android updates

Game-specific notes live under `.notes/gaming/`:

- `gaming/tmodloader-debugging.md` — tModLoader paths and log locations
- `gaming/steam-launch-parameters.md` — per-game Steam launch flags; documents the `tml-prelaunch` script (`shared/modules/home-manager/scripts/gaming/tml-prelaunch.nix`)
- `gaming/launcher-env-variables.md` — common env vars + wrappers for Heroic/Lutris/Faugus/umu/Steam (JP locale, Proton WineD3D, XWayland wrapper, RPG Maker, perf wrappers)
- `gaming/steam-client-menu-bug.md` — Steam's menus self-dismiss on niri because xwayland-satellite 0.8.2 focuses override-redirect windows; `niri-home/core/xwayland.nix` pins past it to upstream `add2795` (PR #494). Drop the pin once nixpkgs ships that commit
- `gaming/minecraft_servers/{GTNH,TerraFirmaGreg-Modern}/` — each pack has `index.md` listing its sub-files (server setup, mods, config tweaks, etc.). **Update the relevant sub-file when that pack's config, mods, or settings change.** The matching declarative modules live at `hosts/laptop/minecraft-servers/{gtnh-server,tfg-server}.nix` (add a new server by creating a `.nix` there and importing it in that dir's `default.nix`).

Android device notes live under `.notes/android/`:

- `android/debloat/Lenovo-Idea-Tab-Pro/` — `index.md` (full redo procedure: never-remove list, install-replacements-first ordering, PMS flush, reboot test, privacy settings) + `removal-list.txt` (the 131 verified-safe packages). **A ZUI OTA restores every stock package, so this gets redone after each system update.**
- `android/vpn-lockdown-allowlist.md` — how to keep Mullvad split tunnelling working with "Block connections without VPN" on. The `always_on_vpn_lockdown_whitelist` secure setting is adb-writable and needs no device owner, but only takes effect on reboot; `nixm vpn-list` / `nixm vpn-edit` wrap it.

Local (non-nixpkgs) binary installs live under `.notes/local/`:

- `local/local-binary-installs.md` — the `~/.local/opt` + `hostConfig.local` pattern for prebuilt third-party bundles kept out of git; restore steps for fresh installs / the laptop. **Add an entry here for each new local app.**
