#=====================================================================#
# DANKMATERIALSHELL THEME
#=====================================================================#
# The DMS registry's Catppuccin Mocha Mauve theme, with Stylix's palette for
# the colours base16 covers, so DMS follows base00 (stylix.nix). Both DMS
# modules point customThemeFile here.
{
  lib,
  machine,
  ...
}: {
  #--- Every user on the machine
  home-manager.users = lib.mapAttrs (_: _: {config, ...}: {
    xdg.configFile."DankMaterialShell/themes/stylix/theme.json".text = with config.lib.stylix.colors.withHashtag;
      builtins.toJSON {
        id = "stylix";
        name = "Catppuccin (Stylix)";
        dark = {
          primary = base0E;
          primaryText = base00;
          primaryContainer = "#55307f";
          secondary = base07;
          surfaceTint = "#33293f";
          surface = base01;
          surfaceText = base05;
          surfaceVariant = base00;
          surfaceVariantText = "#a6adc8";
          background = base00;
          backgroundText = base05;
          outline = base03;
          # Lowest and Low are left out: DMS blends them from surface and
          # surfaceContainer, so they stay darker than base00
          surfaceContainer = base00;
          surfaceContainerHigh = base02;
          surfaceContainerHighest = "#45475a";
          error = base08;
          warning = base09;
          info = base0D;
        };
      };
  }) machine.users;
}
