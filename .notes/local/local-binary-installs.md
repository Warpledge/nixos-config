# Local Binary Installs

Prebuilt third-party apps that aren't in nixpkgs and aren't worth packaging.
They live under `~/.local/opt/` (out of git), and a thin wrapper module in
`shared/modules/home-manager/programs/local/` puts them on PATH with whatever
runtime env they need. Each is gated behind a `hostConfig.local.<name>` toggle.

## The pattern

- **Binary:** unpacked into `~/.local/opt/<name>/` on each machine. Not tracked
  by git, so it has to be restored by hand on a fresh install or the laptop.
- **Wrapper:** `programs/local/<name>.nix` wraps the binary with
  `writeShellScriptBin`, sets any runtime env, and `exec`s it. nix-ld handles
  the ELF interpreter for foreign dynamically linked binaries.
- **Toggle:** `hostConfig.local.<name>` in both host configs, imported in
  `programs/default.nix`.

## Restore on a fresh install / laptop

For each app below, recreate `~/.local/opt/<name>/` from the source, make the
binary executable, then `nixm rebuild`. The wrapper and toggle are already in
git so only the binary bundle needs restoring.

---

## katana-fxfloorboard

- **What:** Boss Katana MK2 amp patch editor (Colin Willcocks' tool).
- **Command:** `katana-fxfloorboard` (also a desktop entry).
- **Location:** `~/.local/opt/katana-fxfloorboard/`
- **Runtime:** bundle ships its own libs (RUNPATH points at `./lib`); wrapper
  only sets `ALSA_CONFIG_PATH` so RtMidi/ALSA can reach the amp.
- **Restore:** unpack the Linux bundle into the folder, keep the `lib/` dir next
  to the `Katana-MK2-FxFloorBoard` binary, `chmod +x` it.

## relink-mod-organizer

- **What:** GUI mod manager for Granblue Fantasy: Relink (RokyZevon). Front end
  over GBFRDataTools with enable/disable toggles and a mods folder, so you're
  not hand-registering each mod.
- **Command:** `relink-mod-organizer` (also a desktop entry).
- **Location:** `~/.local/opt/relink-mod-organizer/`
- **Runtime:** self-contained .NET single-file build (no external dotnet), but
  an Avalonia GUI. The wrapper supplies the libs its bundled Skia/Avalonia
  stack dlopens (fontconfig, freetype, GL, X11, xkbcommon) via
  `LD_LIBRARY_PATH`, and sets `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` to skip
  the ICU dependency. nix-ld handles the ELF interpreter. It also adds
  `/run/opengl-driver/lib` and sets `LIBGL_ALWAYS_SOFTWARE=1`: with hardware
  GLX (Niri -> XWayland, AMD + mesa) the Avalonia window never maps, so it
  falls back to software rendering (fine for a config UI). It's an X11-only
  Avalonia app, and Niri launcher-spawned processes don't inherit `DISPLAY`
  (so it crashed when launched from the app menu but worked from a terminal);
  the wrapper defaults `DISPLAY` to `:0` (where xwayland-satellite runs).
- **Restore:** grab `RelinkModOrganizer-linux-x64.tar.gz` from
  <https://github.com/RokyZevon/RelinkModOrganizer/releases>, extract so the
  `RelinkModOrganizer` binary lands directly in the folder, `chmod +x` it. If a
  future Avalonia build errors on a missing `.so`, add that lib to
  `runtimeLibs` in the wrapper module.
- **Usage:** Settings -> Locate Game (`granblue_fantasy_relink.exe`), Mod List
  -> Open Mods Folder, drop unzipped mod folders in, Reload, enable, "Mod it".

### Managing Relink mods

RMO owns `data.i`. Install/enable/disable/uninstall all happen in the GUI, so
don't hand-edit the game's `data/` folder alongside it. Mods come as
`gbfrelink.<id>/GBFR/data/...` folders (Reloaded/manager format); drop the
unzipped folder into RMO's mods folder and hit "Mod it".

Game path: `~/.local/share/Steam/steamapps/common/Granblue Fantasy Relink`.

**Before a Steam game update:** restore `data.i` from the `orig_data.i` backup
in the game folder first, or Steam's delta patch chokes on the modded index.
Re-apply mods in RMO afterwards. (Verifying game files also restores `data.i`.)

If RMO ever breaks, GBFRDataTools is the underlying CLI it wraps
(<https://github.com/Nenkai/GBFRDataTools/releases>, v1.4.0 = last native Linux
build). The manual path is: copy a mod's `GBFR/data/*` into `<game>/data/`, back
up `data.i` to `orig_data.i`, then `GBFRDataTools add-external-files -i
"<game>/data.i" --overwrite` (needs `dotnet-runtime_9` via `DOTNET_ROOT`).
