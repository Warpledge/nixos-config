# Theme

<!-- Claude Code loads this file when it reads a file in this folder. -->

How an app gets its colours (CLAUDE.md rule 5): DMS's theme picker runs matugen, which renders each app's colour file at runtime: DMS's built-in template where it has one (GTK, qt6ct, kitty, Zed), otherwise a `matugen.templates` entry (the entry sits in `matugen.nix` or in the app's module) with the template in `matugen/` or beside the module, and the app's config includes the rendered file. Rendered files stay plain files nothing else owns: a home-manager store link stops DMS writing or reloading them. Stylix's colour targets are off except VS Code's and the NixOS console's, and catppuccin/nix only themes Plymouth. Apps nothing can recolour at runtime keep fixed Catppuccin Mocha Mauve.

- `matugen.nix` — the `matugen.templates` option, written to `~/.config/matugen/dms/configs/repo.toml`, which DMS appends to every matugen run. The repo templates in `matugen/` are converted from the Catppuccin ports with Mocha's colours mapped to DMS roles and `dank16` slots.
- `dms.nix` — the default DMS theme (Catppuccin Mocha Mauve with Crust as Base, for contrast behind translucent windows; Latte Mauve in light mode), seeded once so the picker's choice sticks.
- `gtk.nix` (adw-gtk3 plus DMS's `dank-colors.css`) and `qt.nix` (qt5ct/qt6ct on matugen's palette, `kdeglobals` from DMS's KDE scheme). `gtk.css`, `qt5ct.conf` and `qt6ct.conf` are copied in place on activation rather than linked: DMS only reloads running apps through files it can read and touch.
- `stylix.nix` for fonts and cursor, `catppuccin.nix` for Plymouth, `fonts.nix`.
- No module sets the wallpaper: DMS picks it at runtime (`Mod+W`) and `wallpapers/` holds the images.

GTK 4 apps recolour only on restart, except Omni Settings, which reloads `dank-colors.css` itself; Zen, GoofCord and KDE apps also read theirs at start. A template whose `{{ }}` placeholders sit in a `.css` file runs Zed's biome language server out of memory, so those are named `.css.matugen`.
