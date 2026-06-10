#=====================================================================#
# CAFFEINE EXTENSION
#=====================================================================#
{pkgs, lib, ...}: {
  home.packages = with pkgs.gnomeExtensions; [
    caffeine
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "caffeine@patapon.info"
    ];
  };
}
