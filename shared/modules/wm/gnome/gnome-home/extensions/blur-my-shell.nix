#=====================================================================#
# BLUR MY SHELL EXTENSION
#=====================================================================#
{pkgs, lib, ...}: {
  home.packages = with pkgs.gnomeExtensions; [
    blur-my-shell
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "blur-my-shell@aunetx"
    ];

    "org/gnome/shell/extensions/blur-my-shell".color-and-noise = false;
    "org/gnome/shell/extensions/blur-my-shell/applications".blur = false;
  };
}
