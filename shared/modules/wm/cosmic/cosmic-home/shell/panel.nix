#=====================================================================#
# COSMIC PANEL LAYOUT
#=====================================================================#
_: let
  #--------------------------------------------------------------------#
  #-- Applet Layout
  #--------------------------------------------------------------------#
  # Rearrange in Settings -> Desktop -> Panel, then copy the IDs back from
  # ~/.config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_* or the next
  # rebuild reverts it.
  #--- Start segment
  leftPlugins = [
    "com.system76.CosmicAppletTiling"
    "net.tropicbliss.CosmicExtAppletCaffeine"
    "com.system76.CosmicAppletTime"
    "com.system76.CosmicAppletWorkspaces"
  ];

  #--- Center segment
  centerPlugins = [
    "com.system76.CosmicAppList"
  ];

  #--- End segment
  rightPlugins = [
    "com.system76.CosmicAppletStatusArea"
    "io.github.cosmic_utils.minimon-applet"
    "com.system76.CosmicAppletAudio"
    "com.system76.CosmicAppletBattery"
    "com.system76.CosmicAppletNetwork"
    "com.system76.CosmicAppletBluetooth"
    "com.system76.CosmicAppletNotifications"
    "com.system76.CosmicAppletPower"
  ];
in {
  #--------------------------------------------------------------------#
  #-- Declarative Panels
  #--------------------------------------------------------------------#
  # This list is authoritative over which panels exist: only "Panel" is
  # declared, so COSMIC's default Dock is removed.
  wayland.desktopManager.cosmic.panels = [
    {
      name = "Panel";

      #--------------------------------------------------------------------#
      #-- Placement
      #--------------------------------------------------------------------#
      anchor = {
        __type = "enum";
        variant = "Top";
      };
      anchor_gap = false;
      margin = 0; # must be 0 when anchor_gap is false
      expand_to_edges = true;
      size = {
        __type = "enum";
        variant = "S";
      };
      output = {
        __type = "enum";
        variant = "All";
      };

      #--------------------------------------------------------------------#
      #-- Appearance
      #--------------------------------------------------------------------#
      # autohide is intentionally undeclared: cosmic-manager emits None but
      # COSMIC 1.5 expects the enum Never, which is already the Panel default.
      background = {
        __type = "enum";
        variant = "ThemeDefault";
      };
      opacity = 0.8;

      #--------------------------------------------------------------------#
      #-- Applets
      #--------------------------------------------------------------------#
      plugins_wings = {
        __type = "optional";
        value = {
          __type = "tuple";
          value = [leftPlugins rightPlugins];
        };
      };
      plugins_center = {
        __type = "optional";
        value = centerPlugins;
      };
    }
  ];
}
