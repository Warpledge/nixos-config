#=====================================================================#
# FORGE EXTENSION SETTINGS
#=====================================================================#
{lib, ...}: let
  inherit (lib.gvariant) mkUint32;
in {
  dconf.settings = with lib.gvariant; {
    "org/gnome/shell/extensions/forge" = {
      focus-border-toggle = true;
      split-border-toggle = true;
      stacked-tiling-mode-enabled = true;
      tabbed-tiling-mode-enabled = true;
      window-gap-hidden-on-single = true;
      window-gap-size = mkUint32 4;
      window-gap-size-increment = mkUint32 1;
    };
  };

  #=====================================================================#
  # FORGE EXTENSION COLOR THEME
  #=====================================================================#
  home.file.".config/forge/stylesheet/forge/stylesheet.css".source = ./stylesheet.css;

  #=====================================================================#
  # FORGE WINDOW RULES & OVERRIDES
  #=====================================================================#
  home.file.".config/forge/config/windows.json".source = ./windows.json;
}
