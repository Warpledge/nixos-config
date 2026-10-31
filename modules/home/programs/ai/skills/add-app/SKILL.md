---
name: add-app
description: Add an application or service to this NixOS repo the way its conventions require (a toggle in the settings template and the user's settings, module, router import, setup.sh's app list, README row and link, Omni Settings description), then check it is wired everywhere. Use whenever the user asks to install, add, enable or package an app, a game launcher, a Flatpak, an AppImage or a system service in this config, even if they only say "can you get X on here".
---

# Add an app

CLAUDE.md's **Add an application** points here; these are its steps plus a check that
catches the step that usually gets missed.

## Before writing anything

- Look up the package with the nixos MCP tool, and check for a home-manager module
  (`find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix'`); `programs.<pkg>`
  beats `home.packages` when it exists.
- Not in nixpkgs: prefer upstream's AppImage, or its `.deb`/tarball patched with
  `autoPatchelfHook` (`gaming/launchers/twintail.nix`, `audio/guitar/tone3000.nix`), over its
  Flatpak (the user's call, after repeated Flatpak trouble on NixOS; Hytale is the only
  Flatpak left, and the user wants Flatpak gone once it has another route). An AppImage goes through `appimageTools` in the folder for what the app
  *is* (`docs/personal/local/appimage-wraps.md`). A Flatpak is the last resort when there's no native build, or the AppImage's bundled libraries clash with the
  host; it gets its own module gated on a toggle, not an inline entry in `flatpak.nix`.
  A prebuilt bundle in `~/.local/opt` gets a wrapper in the folder for what the app is,
  a toggle in that category, and an entry in `docs/personal/local/local-binary-installs.md`.
- Set only what the user asked for, and no colors or fonts (CLAUDE.md rule 5). Colors
  come from DMS's matugen: use DMS's built-in template if it has one for the app,
  otherwise add a repo template under `matugen.templates` and have the app's config
  include the rendered file. Fonts come from `config.stylix.fonts`.
- Install it once: `programs.<pkg>.enable` already adds the package, so don't also list
  it in `home.packages`.
- Option keys inside a freeform set (`programs.<pkg>.options`, `settings`) aren't
  checked by Nix; confirm each against the app's man page (`selection-clipboard`, not a
  guess).
- Put it in a category that already exists in the template, and take only the module
  arguments the module uses (`deadnix --no-lambda-arg <file>` flags the rest).

## Steps

1. **Toggle** in the matching attribute set of `users/_template/settings.nix`, with a short
   comment. The template lists every setting and is what new users start from, so the
   value is `false` unless every new user should get the app. Turn it on where the user
   wants it: `users/<whoami>/settings.nix` for every machine, or one machine's
   `users.<whoami> = {...};` block in `machines/<name>/settings.nix` (the laptop turns
   apps off that way). Add it to the `apps` list in `setup.sh` too, unless it needs a
   `~/.local/opt` bundle. A system service's toggle goes in
   `machines/_template/settings.nix` (off) and on in `machines/<name>/settings.nix`.
2. **Module** in `modules/home/programs/<category>/` (system services:
   `modules/nixos/services/<category>/`). L1 header, short comments per Comment Style.
   An app pinned to an upstream GitHub release (AppImage, `.deb`, jar, tarball) or commit
   also gets an entry in `lib/upstream.json` (a machine's own app: that machine's
   `upstream.json`), so Omni Settings' Pinned Versions and `nixm check-updates` watch it.
3. **Import** in the router, `programs/default.nix` (`gaming.*` apps: `programs/gaming/default.nix`;
   services: `nixos/default.nix`):
   `++ lib.optionals user.<category>.<app> [./<category>/<app>.nix]`. A NixOS-side gate on
   an app reads `anyUser.<category>.<app>` (on when any user of the machine has it), a
   service `machine.<name>.enable`. `gaming.steam` is the exception, wired in
   `nixos/gaming/default.nix` on `anyUser.gaming.steam`. A guitar app goes in
   `audio/guitar/default.nix`, with its toggle added to that folder's gate in
   `programs/default.nix`. The other nested `default.nix` files (`browsers/zen/`,
   `file-browsers/dolphin/`, `media/{freetube,moku}/`, `system/omni-settings/`)
   are module bundles, not routers.
4. `git add <new files>` → `nix flake check` (a new module and import are the
   uncertain case CLAUDE.md rule 1 keeps the check for). The check only evaluates
   the module where its toggle is on, so step 1's toggle must be on somewhere first.
5. **Omni Settings**: add a `descriptions.json` entry for the new setting. Grep for the
   file's last entry to find where to append:
   ```bash
   grep -n '^\s*"[^"]*":' modules/home/programs/system/omni-settings/src/descriptions.json | tail -1
   ```
   Add an object with at least `summary` and `text` (use the package's description from
   `nix eval --raw nixpkgs#<pkg>.meta.description` or write a one-liner; `text` is the
   row's ? tooltip, so keep it under about 200 characters). Include `icon`
   (`.desktop` id or icon name) when known. If the setting is a value used by another
   setting's dropdown (e.g. `fileBrowsers.duxFiles` as a choice for `defaultApps.fileManager`),
   add it to that parent's `choices` object in the same file.
   `descriptions.json` doesn't decide which page the row is on: `PAGES` in `src/schema.py`
   does. An app that belongs beside its siblings on a curated page (an AI app on the AI
   tab) needs its dotted path in that page's list; without one it stays on its template
   section, under Default Packages.
6. **README**: grep, never read it whole (`grep -n '^| \*\*' README.md`,
   `grep -n '^\[.*\]: http' README.md`), add the app to its Components row and a
   `[label]: url` link (homepage from `nix eval --raw nixpkgs#<pkg>.meta.homepage`), plus
   `## Structure` for a new directory and `## Flake Inputs` for a new input. No `---`
   rules; verify with `nix run nixpkgs#pulldown-cmark -- < README.md`.
7. **Check the wiring**:
   ```bash
   bash <skill-dir>/scripts/check-app.sh <category>.<app> <module-path> <readme-label>
   ```
   It confirms the toggle in its template and its value on every machine, whether
   setup.sh offers it, the module staged, the router import pointing at that module (not
   just any file mentioning the toggle), and both README entries.
8. Cut-only pass over any prose written (remove words, add none: no new information or
   claims, no rephrasing that smuggles either in), then hand back for the rebuild; never
   run it yourself.
