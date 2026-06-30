#=====================================================================#
# FORGE EXTENSION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./settings.nix
    ./keybindings.nix
  ];

  home.packages = with pkgs.gnomeExtensions; [
    forge
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "forge@jmmaranan.com"
    ];
  };
}
