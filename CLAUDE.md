# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

NixOS flake managing **Desktop** (Ryzen 5800X3D + RX 9070 XT, 280Hz OLED + 144Hz) and **Laptop** (Legion Slim 5, Ryzen 7735HS + hybrid AMD 680M/RTX 4070, 1600p@165Hz). Nixpkgs unstable, Catppuccin Mocha Mauve via Stylix. Active WM: Niri (Hyprland also supported).

## Critical Rules

1. **Wait for user approval** after file edits before running rebuild commands. User handles all git operations.
2. **`git add` new files before `nix flake check`** — the flake won't see untracked files.
3. **Use surgical edits** (exact `old_string` → `new_string`), never rewrite whole files.
4. **Public repo:** no passwords, API keys, tokens, or secrets.

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
nixm dryrun             # Rebuild without applying
nixm gc                 # GC, keep last 5 generations
nix flake lock --update-input <name>   # Bump a single input
run <pkg> [args]        # Ad-hoc launch a nixpkgs package without installing it (zsh function)
```

`nixm` is an fzf-driven menu defined in `shared/modules/home-manager/scripts/nixm.nix`.

## Architecture

```
flake.nix
  → hosts/{hostname}/{hostname}.nix          (host entry)
    → hosts/{hostname}/hostConfig/core.nix   (toggles, passed as specialArgs)
    → shared/core.nix                        (NixOS + home-manager wiring)
      → shared/modules/{nixos,home-manager}/ (modular configs)
      → shared/modules/wm/${windowManager}/  (active WM only)
```

`hostConfig` from each host's `hostConfig/core.nix` is threaded through `specialArgs`, so every module can read it. Conditional imports in each subdir's `default.nix` decide what loads.

### hostConfig

The authoritative list of toggles is **`hosts/{hostname}/hostConfig/core.nix`** — read it directly, don't trust this file to stay in sync. Current shape (desktop and laptop are kept symmetrical):

- `windowManager` — `"hyprland" | "niri" | "gnome"`
- `kernel` — `"zen" | "latest" | "xanmod" | "cachyos"`
- Service toggles: `mullvad.enable`, `clamav.enable`, `docker.enable`, `winboat.enable`, `sunshine.enable`, `waydroid.{enable,magisk,nftables}`
- Attribute-set toggles: `browsers.{zen,mullvad,helium}`, `terminals.{kitty,ghostty}`, `editors.{helix,zed}`, `fileBrowsers.{nautilus}`, `media.{mpv,spotify,grayjay}`, `creative.{blender,krita}`
- AI tools: `claude.enable`, `opencode.enable`, `lmstudio.enable`

### hostConfig Decision Tree

```
Does this need to be configurable per-host?
├─ NO → Don't use hostConfig, just put it in the module directly
└─ YES
   ├─ Is it mutually exclusive (only one choice makes sense)?
   │  └─ YES → Enum
   │         Example: windowManager, kernel
   │
   ├─ Can you have multiple items at once?
   │  └─ YES → Attribute Set
   │         Example: browsers (install Zen + Brave simultaneously)
   │
   └─ Single feature on/off?
      └─ YES → Boolean with .enable
             Example: mullvad.enable, clamav.enable
```

### hostConfig Best Practices

1. **Default to current behavior** — when adding a new option, default to the state that matches the current config
2. **Use `or` for nested attrs** — `hostConfig.feature.sub or false` when accessing attrs that might not exist
3. **Group related options** — use `browsers = {...}` instead of `zenBrowser = true; braveBrowser = true`
4. **Document valid enum values** — add a comment in hostConfig listing all valid strings
5. **Keep imports clean** — all conditionals in `default.nix`, avoid scattering `mkIf` throughout modules
6. **Sync across hosts** — add to both `hosts/desktop/hostConfig/core.nix` and `hosts/laptop/hostConfig/core.nix`

### hostConfig Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `attribute not found` | Option missing from a host config file | Add to both `hosts/*/hostConfig/core.nix` |
| Module not loading when enabled | Wrong option name or path in conditional import | Check `default.nix` — verify `hostConfig.option` matches exactly |
| Works on desktop but not laptop | Different values per host | Check each `hosts/*/hostConfig/core.nix` |
| `nix flake check` fails | Syntax error in hostConfig file | Check for missing semicolons, unmatched braces |
| Option has no effect | Inline conditional instead of conditional import | Module loading → `lib.optionals`; config logic → `if/then/else` |
| Can't access nested attr | Accessing without checking existence | Use `hostConfig.feature.sub or default_value` |

### hostConfig Validation Checklist

- [ ] Option added to **both** host `hostConfig/core.nix` files
- [ ] Conditional import placed in the relevant `default.nix`
- [ ] Option path in conditional matches definition exactly
- [ ] Tested with option enabled on at least one host
- [ ] `nix flake check` passes
- [ ] Formatted with `alejandra .`
- [ ] Enum values documented in a comment

### Conditional import patterns

```nix
# Single boolean
++ lib.optionals hostConfig.mullvad.enable [./network/mullvad.nix]

# Attribute-set item
++ lib.optionals hostConfig.browsers.zen [./browsers/zen]
++ lib.optionals hostConfig.media.mpv [./media/mpv.nix]

# WM module selection (in shared/core.nix)
imports = [ ./modules/wm/${hostConfig.windowManager} ];
```

### Module layout

- `shared/modules/nixos/` — system: network, nix daemon, security, services, gaming, bootloader/locale/user
- `shared/modules/home-manager/` — user: `programs/` (browsers, terminals, editors, ai, shell, chat-clients, emulation, fetch, file-browsers, creative, media, plus `android.nix`, `gaming.nix`, `git.nix`), services, scripts, mime, variables
- `shared/modules/wm/{hyprland,niri}/` — each has `<wm>-nixos/` and `<wm>-home/`; both integrate DankMaterialShell (DMS)
- `shared/modules/theme/` — stylix, catppuccin, fonts
- `hosts/{hostname}/` — `gpu.nix`, `{hostname}.nix`, `hostConfig/core.nix`, `wm/<wm>.nix` (per-WM host overrides: monitors, GPU env vars, autostart)

### Where to place things

| Scope | Path |
| --- | --- |
| Shared system | `shared/modules/nixos/` |
| Shared user | `shared/modules/home-manager/` |
| Per-host hardware/entry | `hosts/{hostname}/` |
| Per-host toggle | `hosts/{hostname}/hostConfig/core.nix` |
| WM internals | `shared/modules/wm/{wm}/` |
| Per-host WM overrides | `hosts/{hostname}/wm/{wm}.nix` |

## Workflows

**Add an application:**
1. Add the toggle to **both** host configs (keep them symmetrical)
2. Create the module in the right subdir (`shared/modules/home-manager/programs/...`)
3. Add the conditional import in that subdir's `default.nix`
4. `git add` new files → `nix flake check` → `nixm rebuild`

**Add a system service:** same flow, but `shared/modules/nixos/services/<name>.nix` and import in `shared/modules/nixos/default.nix`.

**Switch WM:** change `windowManager` in the host's hostConfig → `nixm rebuild`.

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

**DMS** (DankMaterialShell): shared declarative config lives at `shared/modules/wm/{wm}/{wm}-home/shell/dms/` (`core.nix` + `settings.json` + `clsettings.json`). The DMS keybind helper differs per WM (string interpolation for Hyprland, list concat for Niri).

**Hyprland-only directories:** `core/animations.nix`, `core/variables.nix`, `core/rules/{windowrules,layerrules}/`, `scripts/`.
**Niri-only directories:** `core/monitors.nix`, `core/rules.nix`, `core/xwayland.nix`, `addons/`.

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
- Firewall: TCP 80, 443, 25566 (Minecraft), 7777, 5555. SSH disabled.
- Mullvad: `hostConfig.mullvad.enable` (WireGuard + quantum resistance)
- AdGuard Home: disabled (conflicts with VPN); modules kept under `network/adguardhome/` for reference

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

## Troubleshooting

```bash
nix flake check                  # Syntax (fastest)
nixm rebuild --show-trace        # Full trace
journalctl -xeu <service>        # Service logs
journalctl -b -p err             # Errors this boot
```

Common errors:
- `flake.nix is not available` / file ignored → `git add` it
- `infinite recursion` → circular import or self-referencing conditional
- `attribute missing` → option not declared in the active host's hostConfig
- Slow / hung → check `df -h`; try `nix build --offline`

**Rollback:** `sudo nixos-rebuild switch --rollback`, or pick a generation from the bootloader.

**Laptop GPU:** `lspci | grep -i vga`, `env | grep -E 'DRI|VDPAU|LIBVA|VK'`. Configs: `hosts/laptop/gpu.nix` and `hosts/laptop/wm/{hyprland,niri}.nix`. Verify offload with `nvidia-offload glxinfo | grep "OpenGL renderer"`.

## MCP Servers

- **nixos-mcp** — package/option search and version history (use over `nix search` or scraping `search.nixos.org`).
- **context7** — current library documentation (prefer over web search for SDK/API questions).

## Reference Notes (`.notes/`)

Security/privacy notes live under `.notes/security/`:

- `security/blocklists.md` — uBlock Origin and AdGuard Home filter lists
- `security/ublock-filters.md` — custom uBlock cosmetic filters (paste into uBlock → My Filters)
- `security/android-quic-vpn-leak.md` — QUIC VPN bypass (CVE, May 2026): mitigation via `adb shell device_config put tethering close_quic_connection -1`; re-apply after Android updates

Game-specific notes live under `.notes/gaming/`:

- `gaming/tmodloader-debugging.md` — tModLoader paths and log locations
- `gaming/steam-launch-parameters.md` — per-game Steam launch flags; documents the `tml-prelaunch` script (`shared/modules/home-manager/scripts/gaming/tml-prelaunch.nix`)
- `gaming/launcher-env-variables.md` — common env vars + wrappers for Heroic/Lutris/Faugus/umu/Steam (JP locale, Proton WineD3D, XWayland wrapper, RPG Maker, perf wrappers)
- `gaming/minecraft_servers/{GTNH,TerraFirmaGreg-Modern}/` — each pack has `index.md` listing its sub-files (server setup, mods, config tweaks, etc.). **Update the relevant sub-file when that pack's config, mods, or settings change.**
