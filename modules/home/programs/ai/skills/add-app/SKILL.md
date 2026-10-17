---
name: add-app
description: Add an application or service to this NixOS repo the way its conventions require (a toggle in the settings template and the user's settings, module, router import, setup.sh's app list, README row and link), then check it is wired everywhere. Use whenever the user asks to install, add, enable or package an app, a game launcher, a Flatpak, an AppImage or a system service in this config, even if they only say "can you get X on here".
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

1. **Toggle** in the matching attribute set of `users/_template/settings.nix`, with a short
   comment. The template lists every setting and is what new users start from, so the
   value is `false` unless every new user should get the app. Turn it on where the user
   wants it: `users/warpledge/settings.nix` for every machine, or one machine's
   `users.warpledge = {...};` block in `machines/<name>/settings.nix` (the laptop turns
   apps off that way). Add it to the `apps` list in `setup.sh` too, unless it needs a
   `~/.local/opt` bundle. A system service's toggle goes in
   `machines/_template/settings.nix` (off) and on in `machines/<name>/settings.nix`.
2. **Module** in `modules/home/programs/<category>/` (system services:
   `modules/nixos/services/<category>/`). L1 header, short comments per Comment Style.
3. **Import** in the router, `programs/default.nix` (`gaming.*` apps: `programs/gaming/default.nix`;
   services: `nixos/default.nix`):
   `++ lib.optionals user.<category>.<app> [./<category>/<app>.nix]`. A NixOS-side gate on
   an app reads `anyUser.<category>.<app>` (on when any user of the machine has it), a
   service `machine.<name>.enable`. `gaming.steam` is the exception, wired in
   `nixos/gaming/default.nix` on `anyUser.gaming.steam`.
4. `git add <new files>` → `nix flake check` (a new module and import are the
   uncertain case CLAUDE.md rule 1 keeps the check for).
5. **README**: grep, never read it whole (`grep -n '^| \*\*' README.md`,
   `grep -n '^\[.*\]: http' README.md`), add the app to its Components row and a
   `[label]: url` link (homepage from `nix eval --raw nixpkgs#<pkg>.meta.homepage`). No
   `---` rules.
6. **Check the wiring**:
   ```bash
   bash <skill-dir>/scripts/check-app.sh <category>.<app> <module-path> <readme-label>
   ```
   It confirms the toggle in its template and its value on every machine, whether
   setup.sh offers it, the module staged, the router import pointing at that module (not
   just any file mentioning the toggle), and both README entries.
7. Cut-only pass over any prose written (remove words, add none), then hand back for the
   rebuild; never run it yourself.
