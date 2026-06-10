#=====================================================================#
# SPACE BAR EXTENSION
#=====================================================================#
{pkgs, lib, ...}: let
  inherit (lib.gvariant) mkInt32;
in {
  home.packages = with pkgs.gnomeExtensions; [
    space-bar
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "space-bar@luchrioh"
    ];
    #--------------------------------------------------------------------#
    #-- Space Bar Appearance
    #--------------------------------------------------------------------#
    "org/gnome/shell/extensions/space-bar/appearance" = {
      active-workspace-background-color = "rgba(64,145,191,0.286667)";
      active-workspace-border-radius = mkInt32 10;
      empty-workspace-border-radius = mkInt32 10;
      inactive-workspace-border-radius = mkInt32 10;
      workspace-margin = mkInt32 2;
      workspaces-bar-padding = mkInt32 12;
    };

    #--------------------------------------------------------------------#
    #-- Space Bar Behavior
    #--------------------------------------------------------------------#
    "org/gnome/shell/extensions/space-bar/behavior" = {
      always-show-numbers = false;
      indicator-style = "workspaces-bar";
      position = "left";
      reevaluate-smart-workspace-names = true;
      show-empty-workspaces = true;
      smart-workspace-names = false;
      toggle-overview = false;
    };

    #--------------------------------------------------------------------#
    #-- Space Bar Shortcuts
    #--------------------------------------------------------------------#
    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-activate-workspace-shortcuts = true;
      enable-move-to-workspace-shortcuts = true;
    };

    #--------------------------------------------------------------------#
    #-- Space Bar State
    #--------------------------------------------------------------------#
    "org/gnome/shell/extensions/space-bar/state" = {
      version = mkInt32 27;
    };
  };
}
