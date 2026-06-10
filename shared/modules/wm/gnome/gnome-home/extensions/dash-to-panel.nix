#=====================================================================#
# DASH TO PANEL EXTENSION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.gvariant) mkInt32;
in {
  home.packages = with pkgs.gnomeExtensions; [
    dash-to-panel
  ];

  dconf.settings = with lib.gvariant; {
    "org/gnome/shell".enabled-extensions = lib.mkBefore [
      "dash-to-panel@jderose9.github.com"
    ];
    #--------------------------------------------------------------------#
    #-- Dash to Panel
    #--------------------------------------------------------------------#
    "org/gnome/shell/extensions/dash-to-panel" = {
      # Even when we are not using multiple panels on multiple monitors,
      # the extension still creates them in the config, so we set the same
      # configuration for each (up to 2 monitors).
      panel-positions = builtins.toJSON (lib.genAttrs ["0" "1"] (x: "TOP"));
      panel-sizes = builtins.toJSON (lib.genAttrs ["0" "1"] (x: 32));
      panel-element-positions = builtins.toJSON (lib.genAttrs ["0" "1"] (x: [
        {
          element = "showAppsButton";
          visible = true;
          position = "stackedTL";
        }
        {
          element = "activitiesButton";
          visible = false;
          position = "stackedTL";
        }
        {
          element = "dateMenu";
          visible = true;
          position = "stackedTL";
        }
        {
          element = "leftBox";
          visible = true;
          position = "stackedTL";
        }
        {
          element = "taskbar";
          visible = true;
          position = "centerMonitor";
        }
        {
          element = "centerBox";
          visible = false;
          position = "centered";
        }
        {
          element = "rightBox";
          visible = true;
          position = "stackedBR";
        }
        {
          element = "systemMenu";
          visible = true;
          position = "stackedBR";
        }
        {
          element = "desktopButton";
          visible = false;
          position = "stackedBR";
        }
      ]));
      multi-monitors = true;
      show-apps-icon-file = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
      show-apps-icon-padding = mkInt32 4;
      focus-highlight-dominant = true;
      dot-size = mkInt32 0;
      appicon-padding = mkInt32 2;
      appicon-margin = mkInt32 0;
      trans-use-custom-opacity = false;
      trans-panel-opacity = 0.25;
      show-favorites = false;
      group-apps = true;
      isolate-workspaces = false;
      hide-overview-on-startup = true;
      stockgs-keep-dash = true;
    };
  };
}
