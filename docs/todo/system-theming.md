# System-wide theming with presets

**Goal:** switch the whole desktop between colour presets from one setting, instead of the fixed Catppuccin Mocha Mauve it has now. One candidate preset is the near-black, violet-accent look of PhotoCraft's Studio theme.

Added 2026-10-21. The original ask: "system wide auto theming with multiple presets".

## What's already in the repo

- `modules/theme/stylix.nix` sets `base16Scheme` as an inline attrset: Catppuccin Mocha with `base00` swapped to Crust (`#11111b`) for contrast behind translucent windows. A commented-out line above it loads `catppuccin-mocha.yaml` from `base16-schemes`, which is the shape a preset would take.
- `modules/theme/catppuccin.nix` runs catppuccin/nix (`flavor = "mocha"`, `accent = "mauve"`), which themes its ports directly and ignores Stylix's palette. Where both theme an app, one side is switched off there or in `stylix.nix`.
- `modules/theme/dms.nix` builds DMS's theme from Stylix's palette, so DMS already follows a scheme change.
- Apps carrying Catppuccin values themselves (found by grepping for `catppuccin`, `#11111b` and `#cba6f7`): Zen's `userChrome.css`/`userContent.css`, `editors/zed.nix`, `editors/helix.nix`, `media/spotify.nix`, `discord/discord.nix`, `media/freetube/settings.nix`, `wm/niri/home/dms/settings.json`.
- `stylix.nix` sets GTK's accent to `base0E` (Mauve) to match DMS and Kvantum, rather than Stylix's default `base0D`.

## Options

Two routes, researched 2026-10-21. Pick one before starting.

### Option A: presets through Stylix, applied on rebuild

Stylix stays the theming engine; each preset is a base16 scheme picked from NixOS Settings. Roughly a day: steps 1 and 3 for the apps already on Stylix take an afternoon, and most of the rest is step 3 for Zen's CSS (about 106 hardcoded colours across `userChrome.css` and `userContent.css`) and step 2.

- Most of the desktop already follows Stylix: niri's borders and rules, DMS (`theme/dms.nix`), Open WebUI, GTK, Qt and every Stylix target. Small fixes: `shell/fzf.nix` (4 hardcoded colours), Spotify (18), Helix (`inherits = "catppuccin-mocha"`), Zed's theme name, DMS's quickCapture `color_palette_preset = "catppuccin"`, the fcitx5 theme.
- Write each preset so `base0E` is its accent: GTK, DMS and Kvantum already read the accent from that slot.
- Make it a machine setting first; the login screen and system targets are per machine.
- matugen (below) can generate a preset from one seed colour, such as Studio's `#8b7cf6`, converted to base16.

1. **Decide the preset mechanism.** For example a machine or user setting (`theme = "catppuccin-mocha"`) read in `stylix.nix`, with each preset a `base16-schemes` name or a scheme file in `modules/theme/`. A new setting goes in the `_template` file and gets a `descriptions.json` entry so NixOS Settings shows it as a dropdown.
2. **Handle catppuccin/nix.** Either turn its ports off for non-Catppuccin presets and let Stylix targets cover those apps, or keep it only for the Catppuccin preset. Check which apps lose theming when it's off.
3. **Move hardcoded colours onto the palette.** Each file listed above should read Stylix's colours (`config.lib.stylix.colors`) instead of fixed Catppuccin values.
4. **Wallpaper.** Decide whether a preset also picks wallpapers (DMS sets the wallpaper at runtime; `theme/wallpapers/` holds the images).
5. **Apps neither tool themes.** The ArtCraft apps only have built-in themes (see below). A preset could pin each app's closest built-in theme through `lib/mutable-merge.jq`.

### Option B: DMS themes everything, live

DMS's theme picker recolours the desktop at runtime with no rebuild. Picking a static theme (Catppuccin, a custom JSON) still runs matugen with that theme's colours, which writes each app's theme file. It doesn't happen now because `enableDynamicTheming = false` (`wm/niri/home/dms/default.nix`) keeps `pkgs.matugen` out of DMS's dependencies. Similar effort to Option A, spent on templates instead of preset files.

Coverage, from the template list in DMS's `core/internal/matugen/matugen.go` (pinned source, 2026-10-21):

| | Apps |
| --- | --- |
| DMS template | GTK, qt5ct/qt6ct, kcolorscheme (Dolphin), niri, fcitx5, Zen, Kitty, Ghostty, Zed, VS Code, Neovim, Vesktop/Vencord/Equibop |
| No template | Helix, yazi, bat, btop, starship, eza, delta, atuin, tmux, micro, fzf, FreeTube, Spotify, mpv, GoofCord, opencode, Open WebUI, Kvantum, Papirus folders |
| Can't be live | Fonts, cursor, TTY console, GRUB/limine, Plymouth, login screen |

1. Set `enableDynamicTheming = true` and the default theme in DMS's `settings.json` (merged by `wm/dms-mutable.nix`). Presets become DMS's theme picker, not a NixOS Settings dropdown.
2. Write a user template (`runUserMatugenTemplates`) in the repo for each "No template" app. FreeTube only has built-in themes and may not be templatable.
3. For each app DMS themes, stop home-manager owning its colour file (store links are read-only, and a rebuild would overwrite DMS's write). Include a DMS-written file instead: Ghostty's `config-file`, Kitty's `include`, Zed's and Helix's theme folders.
4. Trim Stylix to fonts, cursor and the TTY, boot and login screens; turn off its colour targets for apps. Drop catppuccin/nix once its apps have templates.
5. Qt moves from Kvantum to qt5ct/qt6ct, which DMS themes.
6. Update CLAUDE.md rule 5 ("Stylix owns theming") and AGENTS.md in the same commit.

Trade-offs: the chosen theme lives in DMS's runtime state, so a rebuild or second machine only gets the default; templates map onto Material roles, so a Catppuccin pick is close to the upstream ports but not identical.

### Tools ruled out (2026-10-21)

- HyDE/Hydenix: `richen604/hydenix` is archived and was Hyprland-only.
- end-4's dots-hyprland: Hyprland and Quickshell dotfiles, not a library.
- nix-colors: reported archived in 2024 ([itera#178](https://github.com/lcleveland/itera/issues/178)). Stylix is built on base16.nix; nothing replaces it as a full engine.
- matugen ([v4.2.0](https://github.com/InioX/matugen/releases/tag/v4.2.0), 2026-08-17) ships a home-manager/NixOS module that generates a Material palette at build time (`programs.matugen.theme.colors`). Useful as a preset generator for Option A, and it's what DMS runs in Option B.

## Candidate presets

**Studio (from PhotoCraft 0.12.0)**, `ThemeKind::Studio` in https://github.com/storytold/photocraft/blob/main/crates/ui-egui/src/theme.rs:

| Role | Colour |
| --- | --- |
| Canvas / background | `#0e0e0f`, dock `#111112` |
| Panels / title bar | `#141415`, cards `#1a1a1c` |
| Fields, borders, separators | `#232326`, `#28282c`, `#26262a` |
| Hover, pressed | `#2c2c30`, `#38383e` |
| Text, dim, faint | `#ececf0`, `#96969e`, `#606068` |
| Accent | `#8b7cf6`, text on accent `#d6d0ff` |
| Danger, warning | `#f06060`, `#f0be5a` |

No base16 scheme matches it, so this preset would be a hand-written scheme file. The closest in nixpkgs' `base16-schemes`:

- `oxocarbon-dark`: neutral greys (`#161616`, `#262626`, `#393939`), text `#f2f4f8`, purple `#be95ff`. A bit lighter than Studio, with a pinker accent.
- `vesper`: darker neutrals (`#101010`), but teal and pink accents.
- `darkviolet`: black with violet, but purple-tinted panels.

A smaller first step: keep Catppuccin and override only `base00` to `base02` with Studio's greys, keeping Mauve.

**ArtCraft built-in theme closest to Studio, per app** (as of 2026-10-21, from each repo's `crates/ui-egui/src/theme.rs`): LightCraft Midnight or Charcoal, VectorCraft Dark + Violet + Modern, EffectCraft Darker, FilmCraft Dark, DesignCraft Dark, PdfCraft/DeckCraft/WordCraft/SoundCraft/CADCraft Dark. FigCraft and GridCraft have no theme choice. PhotoCraft stores it as `"darkTheme": "studio"` in `~/.config/photocraft/preferences.json`; the other apps' keys are only known once each has saved a non-default theme.
