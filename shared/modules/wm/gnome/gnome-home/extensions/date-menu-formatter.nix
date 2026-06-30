#=====================================================================#
# DATE MENU FORMATTER EXTENSION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.gvariant) mkInt32;
in {
  home.packages = with pkgs.gnomeExtensions; [
    date-menu-formatter
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "date-menu-formatter@marcinjakubowski.github.com"
    ];

    "org/gnome/shell/extensions/date-menu-formatter" = {
      apply-all-panels = false;
      font-size = mkInt32 14;
      formatter = "01_luxon";
      pattern = " h : mm a";
      remove-messages-indicator = false;
      text-align = "center";
      use-default-calendar = true;
      use-default-locale = true;
    };
  };
}
