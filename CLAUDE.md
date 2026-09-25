# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

NixOS flake managing **Desktop** (Ryzen 5800X3D + RX 9070 XT, 280Hz OLED + 144Hz) and **Laptop** (Legion Slim 5, Ryzen 7735HS + hybrid AMD 680M/RTX 4070, 1600p@165Hz). Nixpkgs unstable, Catppuccin Mocha Mauve via Stylix. Active WM: Niri; Hyprland, GNOME, and COSMIC modules also exist (Niri and Hyprland are the fully built-out ones).

## Critical Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead. Validation you SHOULD run yourself before reporting done: `alejandra .` → `git add <new files>` → `nix flake check`. The user handles all git operations.
2. **`git add` new files before `nix flake check`** — the flake won't see untracked files.
3. **Use surgical edits** (exact `old_string` → `new_string`), never rewrite whole files.
4. **Public repo:** no passwords, API keys, tokens, or secrets.
5. **Stylix owns theming.** Never set colors, fonts, or wallpaper in a module: enable the program's theming target and let Stylix supply the palette. Hardcoded values conflict with or silently override the theme.
6. **Set only what was asked for.** No extra options, defaults, or "nice to have" settings beyond the request.
7. **No agent attribution in commits.** If asked to write a commit message or PR description, it carries no `Co-Authored-By:` trailer, no "Generated with" line, and no mention of Claude or any agent. The user is the sole author of every commit.

`AGENTS.md` at the repo root is a second, shorter ruleset for other agents (opencode reads it *instead of* `CLAUDE.md`). The two must not contradict each other: when a rule here changes, check whether `AGENTS.md` says the same.

`.claude/` is gitignored, so this repo's Claude settings stay local and are never committed. So are `assign.kat`, `preferences.xml` and `license.txt` at the root: the BOSS Katana FloorBoard app writes them into whatever directory it starts in, and they're runtime artifacts rather than strays to clean up.

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
nixm backup             # Back up FreeTube (subs, playlists, history) and Zen bookmarks (as bookmarks.html) to dated ~/Backups folders
nixm freetube-backup    # FreeTube only (app must be closed)
nixm zen-backup         # Zen only
nixm vpn-list           # Show the Android VPN lockdown allowlist on an adb device
nixm vpn-edit           # Edit that allowlist in $EDITOR (adb-writable, no device owner; applies on reboot)
nix flake lock --update-input <name>   # Bump a single input
run <pkg> [args]        # Ad-hoc launch a nixpkgs package without installing it (zsh function)
```

`nixm` is an fzf-driven menu defined in `shared/modules/home-manager/nixm.nix` (aliased to `n`). Run `nixm <bogus>` to print the full subcommand list.

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

The authoritative list of toggles is **`hosts/{hostname}/hostConfig/core.nix`**. Read it directly, don't trust this file to stay in sync. Current shape (desktop and laptop are kept symmetrical):

- `username` — read by `flake.nix` itself (`inherit (hostConfig) username`), not just by modules
- `windowManager` — `"hyprland" | "niri" | "gnome" | "cosmic"`
- `kernel` — `"zen" | "latest" | "xanmod" | "cachyos"`
- Service toggles: `mullvad.enable` (plus `mullvad.splitTunnel`, a list of command names routed around the VPN), `clamav.enable`, `docker.enable`, `winboat.enable`, `discord.arrpc.enable`, `scrcpy.enable`, `ssh.enable`, `suwayomi.enable`
- Attribute-set toggles: `browsers.{zen,mullvad,helium,ferdium}`, `terminals.{kitty,ghostty}`, `editors.{helix,zed}`, `fileBrowsers.{nautilus,yazi}`, `media.{mpv,spotify,freetube,videoTrimmer,mangayomi,streamlinkTwitchGui}`, `graphics.{blender,krita,affinity}`, `audio.{reaper,guitar,feedback}`, `office.{thunderbird,obsidian,homebank}`, `security.{bleachbit}`, `gameLaunchers.{steam,heroic,prismlauncher,lutris,faugus,twintail,easyrpg}`, `japanese.{ime,vn}`
- `local.{granblueRelinkMods}` — wrappers around prebuilt bundles under `~/.local/opt/` (kept out of git); see `.notes/local/local-binary-installs.md`
- AI tools: `claude.enable`, `opencode.enable`, `lmstudio.enable`

Desktop and laptop should stay byte-identical apart from the header comment and a short list of deliberate differences. As of 2026-09-21 those are `gameLaunchers.heroic` and `discord.arrpc.enable`, both true on desktop and false on laptop (plus a longer trailing comment on `local.granblueRelinkMods` in the laptop file). Verify with `diff hosts/desktop/hostConfig/core.nix hosts/laptop/hostConfig/core.nix` before assuming.

Gotchas. Grep the option name before assuming which file owns it:

- **`boot.kernelModules` silently swallows kernel parameters.** modprobe cannot resolve them, `systemd-modules-load.service` logs `Failed to find module '<param>'` and still exits 0, so the hardening looks applied and is not. Eleven params sat there until 2026-09-22. Check with `grep <param> /proc/cmdline`, not by reading the module.
- `audio.feedback` is the one toggle that does not match its folder: fee[dB]ack lives in `programs/gaming/` as a game, but shares the Katana rig with `audio.guitar`.
- `gameLaunchers.steam` / `.twintail` are wired in `shared/modules/nixos/gaming/default.nix`; `heroic`, `prismlauncher`, `lutris`, `faugus`, `easyrpg` are wired in `home-manager/programs/default.nix`.
- The Katana patch editor is a `~/.local/opt` bundle but does **not** live in `programs/local/`; it moved into `audio/guitar.nix` with the rest of the amp rig, so it has no `local.*` toggle of its own and rides on `audio.guitar`.
- The AI modules and `emulation/winboat.nix` are conditionally imported **and** wrap their body in `config = lib.mkIf hostConfig.<toggle> {...}`, so the inner guard never fires on its own. New modules take the conditional import alone.
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

`shared/core.nix` is also where the overlay list is assembled, where `nixpkgs.config` sets `allowUnfree` and `android_sdk.accept_license`, and where `home-manager.backupFileExtension = "bak"` is set. One overlay lives in that list: the CachyOS kernel one, applied when `hostConfig.kernel == "cachyos"` (`inputs.cachyos-kernel.overlays.pinned`). A new overlay is appended to the same list. Both `system.stateVersion` and `home.stateVersion` are pinned to `25.11`, marked DO NOT CHANGE.

### Module layout

- `shared/modules/nixos/` — system: `gaming/` (default, esync, gamemode, gamescope, java, kernel, steam, twintail), `network/` (core, blockers), `nix/` (core, nh, nixpkgs, substituters), `security/` (apparmor/, auditd, core, kernel, keyring, sudo), `services/` (adb, desktop, docker, flatpak, keyd, power, runners, sound, clamav, ssh, suwayomi), `system/` (bootloader, display-manager, documentation, input, locale, packages, shell, tweaks, user, wayland, zram, japanese-ime)
- `shared/modules/home-manager/` — user: `programs/` (browsers, terminals, editors, ai, shell, emulation, fetch, file-browsers, graphics, audio, media, office, security, launchers, local, gaming, android, discord, plus `core.nix`, `git.nix`). `mime.nix`, `nixm.nix`, `services.nix` and `variables.nix` are single files at that level, not directories
  - `programs/local/` — wrappers for non-nixpkgs prebuilt bundles living in `~/.local/opt/`; the payload is intentionally not in the repo
  - AppImage wraps (`appimageTools`) sit in the folder for what the app is, not how it is packaged: `gaming/feedback.nix`, `media/{mangayomi,streamlink-twitch-gui}.nix`. The payload is hash-pinned into the store, so unlike `programs/local/` nothing lives outside git (see `.notes/local/appimage-wraps.md`)
  - `default.nix` carries a `clearStaleBackups` activation hook that deletes `*.bak` under `~/.config`, `~/.local/{share,state}` before `checkLinkTargets`. This is why HM activation never fails on leftover backups. Don't remove it when debugging a "file exists" error; find the real conflicting file instead.
  - `programs/media/freetube/` — `settings.nix` (mirrored from the app), `blocked-channels.nix` (~2k channel ids in one flat list, sorted by lowercased name under `LC_ALL=C`) and `youtube-dispatch.nix`, the link handler `mime.nix` points `webLinks` at. The first two are **mirrored**: the home-manager module copies `hm_settings.db` over `settings.db` **only when the declared content changes**, and FreeTube rewrites that file from memory when it exits, so close FreeTube before rebuilding, or the copy is clobbered and stays clobbered until the module changes again. Blocklist entries are emitted with a `preferredName` and a placeholder `icon`, because FreeTube re-resolves every entry missing either one, at one API call each. Subscriptions, profiles, playlists and history are **not** in the repo: they are personal data and this flake is public. `nixm freetube-backup` exports them to a dated folder under `~/Backups/FreeTube` instead, in FreeTube's own Export format so its Import reads them back.
- `shared/modules/wm/{hyprland,niri,gnome,cosmic}/` — each has `<wm>-nixos/` and `<wm>-home/`. Only Hyprland and Niri integrate DankMaterialShell (DMS); GNOME uses `gnome-home/extensions/` + `dconf.nix`, COSMIC uses `cosmic-home/shell/{panel,applets}.nix`
- `shared/modules/theme/` — stylix, catppuccin, fonts, plus `gtk.nix` and `qt.nix`, the toolkit theming targets rule 5 routes through
- `shared/modules/mullvad/` — `mullvad-nixos/` (daemon settings + system-package split tunnel) and `mullvad-home/` (tray app + home-package split tunnel). Imported from `shared/core.nix` like the WM, gated on `hostConfig.mullvad.enable`
- `hosts/{hostname}/` — `gpu.nix`, `hardware-configuration.nix`, `{hostname}.nix`, `hostConfig/core.nix`, `wm/<wm>.nix` (per-WM host overrides: monitors, GPU env vars, autostart)
- `hosts/laptop/` also has `swapfile.nix` and `minecraft-servers/` (GTNH + TerraFirmaGreg server definitions, plus `mcservers.nix`, an fzf picker over them). `minecraft-servers/` is a **home-manager** module injected from `laptop.nix` via `home-manager.users.${username}.imports`, not a NixOS module, and the only place in the repo that reaches into HM from a host entry file.

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
3. Add the conditional import to `shared/modules/home-manager/programs/default.nix`, the only router under `programs/`. The nested `default.nix` files (`browsers/{zen,mullvad,helium}/`, `media/freetube/`) are multi-file module bundles, not routers
4. `alejandra .` → `git add` new files → `nix flake check` (do not rebuild; hand it back)
5. Give any prose the task wrote or edited a cut-only revision pass before handing back: remove words, add none. No new information, no new claims, no rephrasing that smuggles either in. See **Writing Style**.
6. Add it to the matching `<details>` table under **Components** in `README.md` (and `## Structure` if a new directory was created), plus its link-reference definition at the bottom: the README is the public-facing doc and drifts easily.

   **`README.md` is ~25 KB. Never read it in full.** Grep the two regions you need, then edit those lines directly:

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
"sync freetube":

1. **Close FreeTube first.** `~/.config/FreeTube/settings.db` is rewritten from memory on
   exit, so a capture taken while it runs is stale, and a rebuild while it runs gets
   clobbered.
2. **It is a NeDB append-log** — later lines supersede earlier ones with the same `_id`.
   Always reduce before reading:
   `jq -rs 'reduce .[] as $x ({}; .[$x._id] = $x.value)' settings.db`
   The blocklist lives inside settings as `channelsHidden`, a JSON **string** needing `fromjson`.
3. **Blocklist** — diff live ids against `(mk "…"` in the module, emit new ones as
   `(mk "UC…" "Name")`, then re-sort the whole list by lowercased name under `LC_ALL=C`.
4. **Validate**: entry count, no duplicate ids, id set unchanged except the intended delta,
   and every entry still has a non-empty `preferredName` + `icon`.
5. `alejandra .` → `nix flake check`, then hand back for the rebuild, with the app still closed.

Subscriptions, profiles, playlists and history are **not** declarative. `nixm freetube-backup`
writes them to `~/Backups/FreeTube/<YYYY-MM-DD_HH-MM-SS>/` as
`freetube-{subscriptions,playlists,watch-history}.db`, one JSON document per line, which is what
FreeTube's own Export writes and its Import reads. The 10 newest folders are kept; `backup_prune`
only matches names in stamp form, so anything else under that directory is left alone. A run
that exports nothing removes its own folder and exits 1, so it never displaces a real backup.
Restoring goes through the app's Settings → Data Settings → Import, not by copying files
into place.

**Add a system service:** same flow, but `shared/modules/nixos/services/<name>.nix` and import in `shared/modules/nixos/default.nix`.

**Switch WM:** change `windowManager` in the host's hostConfig, then hand back for the rebuild.

**Customize WM:** edit `shared/modules/wm/{wm}/{wm}-home/...` for shared behavior, or `hosts/{hostname}/wm/{wm}.nix` for per-host overrides (monitors, GPU env vars).

## Window Managers

**Keybind syntax differs per WM, so never mix them.**

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

A string like `"dms ipc call spotlight"` in Niri only runs `dms` and drops the rest, so use `["dms" "ipc" "call"] ++ lib.splitString " " action`.

COSMIC is the opposite of Niri: `Spawn` is a **single string** run through `/bin/sh -c`, so arguments and shell syntax belong inline and must *not* be split into a list (`shared/modules/wm/cosmic/cosmic-home/core/binds.nix`):
```nix
{key = "XF86AudioStop"; action = arg "Spawn" "playerctl pause";}          # one string
{key = "Super+F";       action = plain "Maximize";}                       # nullary enum
{key = "Super+Tab";     action = enumArg "System" "WorkspaceOverview";}   # nested enum
```

GNOME defines no keybinds of its own beyond dconf. It is a light-weight fallback, not a peer of Niri/Hyprland/COSMIC.

**DMS** (DankMaterialShell): Niri and Hyprland only. Declarative config lives at `shared/modules/wm/{wm}/{wm}-home/shell/dms/`. Hyprland has `core.nix` + `settings.json`; Niri additionally has `clsettings.json` and `niri-cheatsheet.json`. The DMS keybind helper differs per WM (string interpolation for Hyprland, list concat for Niri).

DMS runs as a systemd user service (`systemd.enable`, `niri.enableSpawn = false`), so it inherits the **systemd user manager** environment (`shared/modules/home-manager/variables.nix`), not niri's `programs.niri.settings.environment` block. It launches every app with `systemd-run --user --scope`, so those session variables, and not niri's, govern anything started from the spotlight. Keep the two sets compatible: `QT_QPA_PLATFORM` and `GDK_BACKEND` must keep their X11 fallbacks (`wayland;xcb`, `wayland,x11`) or X11-only apps die instantly from the launcher while still working from a terminal: a Qt app with no wayland plugin aborts in ~50 ms, a JUCE/GTK one exits with "cannot open display". Diagnose by diffing `tr '\0' '\n' < /proc/$(pgrep -x .quickshell-wra)/environ` against `env`, then replaying with `env -i "${DMS_ENV[@]}" <app>`. A rebuild alone does not fix a bad value: the running manager keeps the old import, so `systemctl --user set-environment` then restart `dms.service`, or log out.

**XDG portals** (Niri): `niri-nixos/default.nix` strips `GDK_BACKEND` from `xdg-desktop-portal-gnome`, and `niri-home/core/portals.nix` adds the gtk backend back. Read `.notes/wm/niri-xdg-portals.md` before touching either, and never "fix" a portal by dropping the X11 fallback from `variables.nix`.

**COSMIC** config goes through the `cosmic-manager` flake input (`cosmic-home/default.nix`), which applies it with `cosmic-ctl` instead of symlinking. Never go back to `xdg.configFile` + `force = true`, and never put `$` in a `Spawn` string. Read `.notes/wm/cosmic-manager.md` before editing COSMIC panels, applets or binds.

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
- Firewall: TCP 22 (open; sshd only runs when `hostConfig.ssh.enable` is set), 80, 443, 25566 (Minecraft), 7777 (Terraria), 5555 (ADB); UDP 27000–27036 range (Steam). Defined in `shared/modules/nixos/network/core.nix`.
- Mullvad: `hostConfig.mullvad.enable` (WireGuard + quantum resistance), `shared/modules/mullvad/`, split across `mullvad-nixos/` (daemon settings, split tunnel) and `mullvad-home/` (tray app). Settings are applied with the `mullvad` CLI from a oneshot unit, not by templating `settings.json`, which the daemon rewrites. Relay and entry selection are deliberately unmanaged so exits can be switched by hand. `hostConfig.mullvad.splitTunnel` names apps routed around the VPN; the NixOS half wraps system packages, the home half wraps `home.packages` ones, and the home profile outranks `/run/current-system/sw/bin` in PATH, so a NixOS wrapper for an HM package is silently shadowed.
- `network/blockers.nix` — hosts-level blocklists, always imported

## Security

LUKS, kernel hardening, AppArmor, GNOME Keyring, auditd. Mullvad VPN as above. Wheel needs a password for sudo, so `nixm rebuild` prompts once; the NOPASSWD list in `security/sudo.nix` covers only sync, poweroff, reboot, shutdown and dmesg. Keep it to commands that cannot be turned into a root shell (sed, systemctl and nixos-rebuild all can).

Audit tooling is `lynis` (configuration) and `sbomnix`/`vulnxscan` (CVE scanning against the real closure, via osv.dev). **Do not go back to `vulnix`**: it only knows NVD's legacy JSON 1.1 feeds, which return 403 since their retirement, so every run ends in a `ConnectionError` traceback. Verified 2026-09-22, when the NVD API 2.0 answered 200 from the same machine.

**AppArmor profiles** live in `shared/modules/nixos/security/apparmor/`, one module per app (gated on that app's hostConfig toggle), all in `complain` mode. Attach them by store-path glob (`/nix/store/*-mpv-*/bin/mpv`), never to a binary Nix builds also run (unzip, tar). `nix flake check` does not parse profiles, so test-compile them before handing back: build `.#nixosConfigurations.<host>.config.environment.etc."apparmor.d".source`, then run `apparmor_parser -Q -K -I <that dir> -I <apparmor-profiles>/etc/apparmor.d <file>` on each profile (no root needed). Log reading, the enforce procedure and known gaps are in `.notes/security/apparmor.md`.

`hostConfig.ssh.enable` gates `nixos/services/ssh.nix`, which owns both sshd and fail2ban: key-only auth, no root login, no forwarding, ed25519 host key, and the fail2ban sshd jail. An assertion refuses to build when the toggle is on and `authorizedKeys.keys` in that module is empty, since password and keyboard-interactive auth are both off and there would be no way in.

## Writing Style

Covers everything with prose in it: chat replies, `README.md`, `.notes/`, commit
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
words over jargon. In `README.md` and `.notes/` prose also skip em dashes; a
colon, a comma, parentheses, or two sentences all work. This applies to dashes
inside a sentence. A dash separating a label from its description in a list
(`` `path/` — what it holds ``) is structure, not prose, and stays.

Structure is not the problem and should stay. The bold-label bullet listing
(`**Short label:** description`) is the house style for `README.md` and stays
even when the wording around it gets loosened up.

`.notes/` carries three extra rules, because a note is read months later with
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

- **L1** — `#====...====#` then `# FILE PURPOSE (UPPERCASE)`, one file-purpose header per file
- **L2** — `#----...----#` then `#-- Section Name` (title case, no closing rule)
- **L3** — `#--- Item description`
- **L4** — inline `# comment` (explain *why*, not *what*)

Spacing: 1 blank line before each header level, 1 after L1, none between L3 items, 1 after closing braces. Alejandra collapses multiple blank lines to one.

When reformatting an existing file: add headers, normalize spacing, convert inline markers to the hierarchy above. **Never delete content**, including commented-out code and disabled options.

### Comment Style

**Keep comments short. A comment earns its place by saving the next reader a trip to the docs, not by narrating.** One or two lines is normal; a paragraph is a smell.

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

**Filter at the source.** Man pages, store listings, and long files go through `grep`/`sed`. Never dump one into the conversation. Target the path you want rather than listing a directory, and if you need several sections of the same document, dump it once to a file and grep that.

**Stop once you have the answer.** A package's own man page is authoritative for its config syntax; don't go on to read the nixpkgs derivation or build inputs, which describe how it is built, not how it is configured. Don't guess documentation URLs: if two web fetches fail, fall back to a local source.

## Reference Notes (`.notes/`)

Security/privacy notes live under `.notes/security/`:

- `security/blocklists.md` — uBlock Origin and AdGuard Home filter lists
- `security/ublock-filters.md` — custom uBlock cosmetic filters (paste into uBlock → My Filters)
- `security/android-quic-vpn-leak.md` — QUIC VPN bypass (CVE, May 2026): mitigation via `adb shell device_config put tethering close_quic_connection -1`; re-apply after Android updates
- `security/apparmor.md` — the per-app AppArmor profiles: what each attaches to, reading `apparmor="ALLOWED"` log lines, moving a profile to enforce, and what breaks first when you do

Game-specific notes live under `.notes/gaming/`:

- `gaming/tmodloader-debugging.md` — tModLoader paths and log locations
- `gaming/steam-launch-parameters.md` — per-game Steam launch flags; documents the `tml-prelaunch` script (`shared/modules/home-manager/programs/gaming/tml-prelaunch.nix`)
- `gaming/launcher-env-variables.md` — common env vars + wrappers for Heroic/Lutris/Faugus/umu/Steam (JP locale, Proton WineD3D, XWayland wrapper, RPG Maker, perf wrappers)
- `gaming/steam-client-menu-bug.md` — Steam's menus self-dismiss on niri because xwayland-satellite 0.8.2 focuses override-redirect windows; `niri-home/core/xwayland.nix` pins past it to upstream `add2795` (PR #494). Drop the pin once nixpkgs ships that commit
- `gaming/minecraft_servers/{GTNH,TerraFirmaGreg-Modern}/` — each pack has `index.md` listing its sub-files (server setup, mods, config tweaks, etc.). **Update the relevant sub-file when that pack's config, mods, or settings change.** The matching declarative modules live at `hosts/laptop/minecraft-servers/{gtnh-server,tfg-server}.nix` (add a new server by creating a `.nix` there, importing it in that dir's `default.nix`, and adding a line to the hardcoded pack list in `mcservers.nix`, the fzf picker that names each pack with its version and dispatches to that server's command).

Android device notes live under `.notes/android/`:

- `android/debloat/Lenovo-Idea-Tab-Pro/` — `index.md` (full redo procedure: never-remove list, install-replacements-first ordering, PMS flush, reboot test, privacy settings) + `removal-list.txt` (the 131 verified-safe packages). **A ZUI OTA restores every stock package, so this gets redone after each system update.**

Local (non-nixpkgs) binary installs live under `.notes/local/`:

- `local/local-binary-installs.md` — the `~/.local/opt` + `hostConfig.local` pattern for prebuilt third-party bundles kept out of git; restore steps for fresh installs / the laptop. **Add an entry here for each new local app.**
- `local/appimage-wraps.md` — the `appimageTools.wrapType2` pattern for upstream AppImages (Mangayomi). Hash-pinned into the store, so nothing to restore by hand; covers the per-app `Exec`/icon fixups, a non-executable `AppRun`, how to get a new hash when `nix store prefetch-file` hits the daemon's DNS timeout, and building one module without a rebuild.

Window manager notes live under `.notes/wm/`:

- `wm/niri-xdg-portals.md` — why `xdg-desktop-portal-gnome` drops to Settings-only when `GDK_BACKEND` is set, how niri-flake hides the system portal backends, and the `busctl` health check
- `wm/cosmic-manager.md` — how cosmic-manager applies config, the `$`-in-`Spawn` RON trap, panel/applet config traps, and the DMS bar the COSMIC panel mirrors
