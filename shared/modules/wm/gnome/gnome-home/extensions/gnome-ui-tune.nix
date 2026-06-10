#=====================================================================#
# GNOME UI TUNE EXTENSION
#=====================================================================#
{pkgs, lib, ...}: {
  home.packages = with pkgs.gnomeExtensions; [
    gnome-40-ui-improvements
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "gnome-ui-tune@itstime.tech"
    ];

    "org/gnome/shell/extensions/gnome-ui-tune" = {
      always-show-thumbnails = true;
      hide-search = true;
      increase-thumbnails-size = "250%";
      overview-firefox-pip = true;
      restore-thumbnails-background = true;
    };
  };
}
