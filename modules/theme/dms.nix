#=====================================================================#
# DANKMATERIALSHELL THEME
#=====================================================================#
# The DMS registry's Catppuccin Mocha Mauve theme with Crust (11111b) for
# Base (Latte in light mode), the default DMS seeds. DMS's matugen colours each
# app from the theme picked in its settings, so this file is the starting preset,
# not a lock.
{
  lib,
  machine,
  ...
}: {
  #--- Every user on the machine
  home-manager.users =
    lib.mapAttrs (_: _: {
      xdg.configFile."DankMaterialShell/themes/catppuccin-crust/theme.json".text = builtins.toJSON {
        id = "catppuccin-crust";
        name = "Catppuccin Crust";
        dark = {
          primary = "#cba6f7"; # Mauve
          primaryText = "#11111b";
          primaryContainer = "#55307f";
          secondary = "#b4befe"; # Lavender
          surfaceTint = "#33293f";
          surface = "#181825"; # Mantle
          surfaceText = "#cdd6f4";
          surfaceVariant = "#11111b";
          surfaceVariantText = "#a6adc8";
          background = "#11111b";
          backgroundText = "#cdd6f4";
          outline = "#6c7086"; # Overlay 0
          # Lowest and Low are left out: DMS blends them from surface and
          # surfaceContainer, so they stay darker than Crust
          surfaceContainer = "#11111b";
          surfaceContainerHigh = "#313244"; # Surface 0
          surfaceContainerHighest = "#45475a"; # Surface 1
          error = "#f38ba8"; # Red
          warning = "#fab387"; # Peach
          info = "#89b4fa"; # Blue
        };
        # The registry's Latte Mauve, for DMS's light mode
        light = {
          primary = "#8839ef"; # Mauve
          primaryText = "#eff1f5";
          primaryContainer = "#eadcff";
          secondary = "#7287fd"; # Lavender
          surfaceTint = "#eadcff";
          surface = "#e6e9ef"; # Mantle
          surfaceText = "#4c4f69";
          surfaceVariant = "#eff1f5";
          surfaceVariantText = "#6c6f85";
          background = "#eff1f5"; # Base
          backgroundText = "#4c4f69";
          outline = "#9ca0b0"; # Overlay 0
          surfaceContainer = "#e6e9ef";
          surfaceContainerHigh = "#ccd0da"; # Surface 0
          surfaceContainerHighest = "#bcc0cc"; # Surface 1
          error = "#d20f39"; # Red
          warning = "#fe640b"; # Peach
          info = "#1e66f5"; # Blue
        };
      };
    })
    machine.users;
}
