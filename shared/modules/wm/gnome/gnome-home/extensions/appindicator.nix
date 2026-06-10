#=====================================================================#
# APPINDICATOR SUPPORT EXTENSION
#=====================================================================#
{pkgs, lib, ...}: {
  home.packages = with pkgs.gnomeExtensions; [
    appindicator
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "appindicatorsupport@rgcjonas.gmail.com"
    ];
  };
}
