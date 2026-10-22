#=====================================================================#
# DANKMATERIALSHELL THEME
#=====================================================================#
# The DMS registry's Catppuccin Mocha Mauve theme with Crust (11111b) for
# Base, the default DMS seeds. DMS's matugen colours each app from the theme
# picked in its settings, so this file is the starting preset, not a lock.
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
      };
    })
    machine.users;
}
