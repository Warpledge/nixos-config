---
name: add-app
description: Add an application or service to this NixOS repo the way its conventions require (hostConfig toggle on both hosts, module, router import, README row and link), then check it is wired everywhere. Use whenever the user asks to install, add, enable or package an app, a game launcher, a Flatpak, an AppImage or a system service in this config, even if they only say "can you get X on here".
---

# Add an app

The workflow is **Add an application** in CLAUDE.md; this is its checklist plus a check
that catches the step that usually gets missed.

## Before writing anything

- Look up the package with the nixos MCP tool, and check for a home-manager module
  (`find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix'`); `programs.<pkg>`
  beats `home.packages` when it exists.
- Not in nixpkgs: prefer upstream's AppImage, or its `.deb`/tarball patched with
  `autoPatchelfHook` (`gaming/launchers/twintail.nix`, `audio/guitar/tone3000.nix`), over its
  Flatpak (the user's call, after repeated Flatpak trouble on NixOS; Hytale is the only
  Flatpak left). An AppImage goes through `appimageTools` in the folder for what the app
  *is* (`docs/local/appimage-wraps.md`). A Flatpak is the last resort when there's no native build, or the AppImage's bundled libraries clash with the
  host; it gets its own module gated on a toggle, not an inline entry in `flatpak.nix`.
  A prebuilt bundle in `~/.local/opt` gets a wrapper in the folder for what the app is,
  a toggle in that category, and an entry in `docs/local/local-binary-installs.md`.
- Set only what the user asked for; Stylix owns colors and fonts, so enable the program's
  theming target instead of setting any.

## Steps

1. **Toggle on both hosts**, same value and comment, in the matching attribute set of
   `hosts/{desktop,laptop}/settings.nix` (they stay byte-identical apart from the
   listed deliberate differences).
2. **Module** in `shared/modules/home/programs/<category>/` (system services:
   `shared/modules/nixos/services/<category>/`). L1 header, short comments per Comment Style.
3. **Import** in the router, `programs/default.nix` (`gaming.*` apps: `programs/gaming/default.nix`;
   services: `nixos/default.nix`):
   `++ lib.optionals hostConfig.<category>.<app> [./<category>/<app>.nix]`.
   `gaming.steam` is the exception, wired in `nixos/gaming/default.nix`.
4. `alejandra .` → `git add <new files>` → `nix flake check`.
5. **README**: grep, never read it whole (`grep -n '^| \*\*' README.md`,
   `grep -n '^\[.*\]: http' README.md`), add the app to its Components row and a
   `[label]: url` link (homepage from `nix eval --raw nixpkgs#<pkg>.meta.homepage`). No
   `---` rules.
6. **Check the wiring**:
   ```bash
   bash <skill-dir>/scripts/check-app.sh <category>.<app> <module-path> <readme-label>
   ```
   It confirms the toggle on both hosts, the module staged, the router import pointing at
   that module (not just any file mentioning the toggle), and both README entries.
7. Cut-only pass over any prose written (remove words, add none), then hand back for the
   rebuild; never run it yourself.
