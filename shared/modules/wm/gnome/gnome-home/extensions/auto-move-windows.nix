#=====================================================================#
# AUTO MOVE WINDOWS EXTENSION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs.gnomeExtensions; [
    auto-move-windows
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
    ];

    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "steam.desktop:6"
        "spotify.desktop:8"
        "vesktop.desktop:9"
      ];
    };
  };
}
