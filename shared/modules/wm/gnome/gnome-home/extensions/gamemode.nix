#=====================================================================#
# GAMEMODE SHELL EXTENSION
#=====================================================================#
{pkgs, lib, ...}: {
  home.packages = with pkgs.gnomeExtensions; [
    gamemode-shell-extension
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "gamemodeshellextension@trsnaqe.com"
    ];
  };
}
