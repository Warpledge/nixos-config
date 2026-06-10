#=====================================================================#
# ASTRA MONITOR EXTENSION
#=====================================================================#
{pkgs, lib, ...}: {
  home.packages = with pkgs.gnomeExtensions; [
    astra-monitor
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "monitor@astraext.github.io"
    ];

    "org/gnome/shell/extensions/astra-monitor" = {
      compact-mode = true;
      compact-mode-start-expanded = true;
      memory-header-value = true;
      network-header-show = false;
      processor-header-percentage = true;
      storage-header-percentage = true;
    };
  };
}
