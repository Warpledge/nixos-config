# Theme

<!-- Claude Code loads this file when it reads a file in this folder. -->

- `matugen.nix` — the `matugen.templates` option, written to `~/.config/matugen/dms/configs/repo.toml`, which DMS appends to every matugen run. The repo templates in `matugen/` are converted from the Catppuccin ports with Mocha's colours mapped to DMS roles and `dank16` slots.
- `dms.nix` — the default DMS theme (Catppuccin Mocha Mauve with Crust as Base, for contrast behind translucent windows), seeded once so the picker's choice sticks.
- `gtk.nix` (adw-gtk3 plus DMS's `dank-colors.css`) and `qt.nix` (qt5ct/qt6ct on matugen's palette, `kdeglobals` from DMS's KDE scheme). `gtk.css`, `qt5ct.conf` and `qt6ct.conf` are copied in place on activation rather than linked: DMS only reloads running apps through files it can read and touch.
- `stylix.nix` for fonts and cursor, `catppuccin.nix` for Plymouth, `fonts.nix`.
- No module sets the wallpaper: DMS picks it at runtime (`Mod+W`) and `wallpapers/` holds the images.

GTK 4 apps recolour only on restart, except Omni Settings, which reloads `dank-colors.css` itself; Zen, GoofCord and KDE apps also read theirs at start. A template whose `{{ }}` placeholders sit in a `.css` file runs Zed's biome language server out of memory, so those are named `.css.matugen`.
