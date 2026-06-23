# Local Binary Installs (`~/.local/opt`)

Prebuilt third-party apps that aren't in nixpkgs. The Nix modules (wrapper +
desktop entry + toggle) live in the repo, but the **binary bundle itself is
kept out of git** under `~/.local/opt/<app>/`. A fresh NixOS install or the
laptop needs the bundle restored manually before the toggle does anything.

## How the pattern works

| Piece | Location | In git? |
| --- | --- | --- |
| Toggle | `hosts/*/hostConfig/core.nix` → `local = { ... }` | yes |
| Wrapper + desktop entry | `shared/modules/home-manager/programs/local/<app>.nix` | yes |
| Conditional import | `shared/modules/home-manager/programs/default.nix` (`hostConfig.local.<app>`) | yes |
| The actual binary bundle | `~/.local/opt/<app>/` | **no — restore manually** |

The wrapper runs the unpatched bundle via the system-wide `nix-ld`
(`shared/modules/nixos/services/runners.nix`) and injects whatever env the app
needs (e.g. `ALSA_CONFIG_PATH`). The bundle ships its own libraries via RUNPATH,
so usually only the dynamic loader (nix-ld) and a couple of env vars are missing.

## Restoring on a fresh install / the laptop

1. Get the bundle (restore a backup, or re-download from the upstream source).
2. Place it at the exact path the wrapper expects:
   ```bash
   mkdir -p ~/.local/opt
   mv <extracted-folder> ~/.local/opt/<app>
   chmod +x ~/.local/opt/<app>/<binary>
   ```
   The folder name must match what the module hardcodes.
3. Flip the toggle in that host's `hostConfig/core.nix`:
   ```nix
   local = {
     <app> = true;
   };
   ```
4. `nixm rebuild`.

> Keep a durable copy of each bundle archive somewhere outside the repo
> (backup/cloud). The repo can't hold it, and upstream downloads can vanish or
> change format.

## Adding a new local app

1. Drop the bundle at `~/.local/opt/<app>/`.
2. Create `shared/modules/home-manager/programs/local/<app>.nix` — wrap the
   binary with `writeShellScriptBin`, set any needed env, add an
   `xdg.desktopEntries.<app>` entry.
3. Add the conditional import in `programs/default.nix` under the
   `#--- Local Packages` section.
4. Add the `<app>` key to `local = { ... }` in **both** host configs (enabled
   where you want it, `false` elsewhere).
5. `git add` the new file → `nix flake check` → `nixm rebuild`.

---

## Installed apps

### katana-fxfloorboard — Boss Katana MK2 patch editor

- **Module:** `shared/modules/home-manager/programs/local/katana-fxfloorboard.nix`
- **Bundle path:** `~/.local/opt/katana-fxfloorboard/`
- **Binary:** `Katana-MK2-FxFloorBoard`
- **Source:** Katana FxFloorBoard for MK2 by Colin Willcocks — free download
  from the project's SourceForge page only (per the bundle's `readme.txt`):
  <https://sourceforge.net/projects/fxfloorboard/files/KatanaFxFloorBoard/>.
  Get the Linux build for Katana MK2 Firmware 2.
- **Env needed:** `ALSA_CONFIG_PATH` → nixpkgs `alsa-lib`'s `share/alsa/alsa.conf`
  (without it, RtMidi can't open the ALSA sequencer and the app crashes).
- **Hosts:** desktop `true`, laptop `false`.
- **Usage:** set the amp's USB to **KATANA CTRL** MIDI mode, then in the app go
  **Tools → Preferences → Midi/USB** and select the KATANA device for input and
  output. Debug from a terminal with `katana-fxfloorboard`; `aconnect -l`
  confirms the kernel sees the amp's MIDI port.
