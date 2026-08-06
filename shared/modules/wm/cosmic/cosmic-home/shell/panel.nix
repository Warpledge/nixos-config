#=====================================================================#
# COSMIC PANEL LAYOUT
#=====================================================================#
{lib, ...}: let
  #--------------------------------------------------------------------#
  #-- RON Helper
  #--------------------------------------------------------------------#
  # cosmic-config stores one file per key under
  # ~/.config/cosmic/<component>/v1/<key>, each holding a bare RON value.
  # Only the two plugin lists are declared here, so every other panel key
  # (size, anchor, opacity, autohide, ...) stays a plain mutable file that
  # Settings can still write.
  ronList = plugins: "[" + lib.concatMapStringsSep ", " (p: ''"${p}"'') plugins + "]";

  #--------------------------------------------------------------------#
  #-- Applet Layout
  #--------------------------------------------------------------------#
  #--- Left
  leftPlugins = [
    "com.system76.CosmicPanelWorkspacesButton" # DMS showWorkspaceSwitcher
    "com.system76.CosmicPanelAppButton" # App library
    "com.system76.CosmicPanelLauncherButton" # DMS showLauncherButton (Mod+A spotlight)
  ];

  #--- Center
  centerPlugins = [
    "com.system76.CosmicAppletTime" # DMS showClock
  ];

  #--- Right
  # Ordered so the monitoring readouts sit left of the status cluster, which
  # is roughly where DMS puts them.
  rightPlugins = [
    "io.github.cosmic_utils.minimon-applet" # DMS CPU/mem/GPU/temp widgets
    "dev.DBrox.CosmicPrivacyIndicator" # DMS showPrivacyButton
    "net.tropicbliss.CosmicExtAppletCaffeine" # DMS idle inhibitor
    "com.system76.CosmicAppletInputSources" # Keyboard layout / IME
    "com.system76.CosmicAppletA11y" # Accessibility
    "com.system76.CosmicAppletStatusArea" # DMS showSystemTray
    "com.system76.CosmicAppletTiling" # Tiling toggle (no DMS equivalent)
    "com.system76.CosmicAppletAudio" # DMS controlCenterShowAudioIcon
    "com.system76.CosmicAppletBluetooth" # DMS controlCenterShowBluetoothIcon
    "com.system76.CosmicAppletNetwork" # DMS controlCenterShowNetworkIcon + VPN
    "com.system76.CosmicAppletBattery" # DMS showBattery
    "com.system76.CosmicAppletNotifications" # DMS showNotificationButton
    "com.system76.CosmicAppletPower" # DMS powermenu
  ];
in {
  #--------------------------------------------------------------------#
  #-- Declarative Panel Plugin Lists
  #--------------------------------------------------------------------#
  # force is needed because COSMIC writes real files into this directory on
  # first launch; without it activation would only rename them to *.bak.
  #
  # Trade-off: these two keys become read-only store symlinks, so the applet
  # add/remove/reorder controls in Settings -> Desktop -> Panel stop saving.
  # Edit the lists above instead.
  xdg.configFile = {
    "cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings" = {
      force = true;
      text = "Some((${ronList leftPlugins},${ronList rightPlugins}))";
    };

    "cosmic/com.system76.CosmicPanel.Panel/v1/plugins_center" = {
      force = true;
      text = "Some(${ronList centerPlugins})";
    };
  };
}
