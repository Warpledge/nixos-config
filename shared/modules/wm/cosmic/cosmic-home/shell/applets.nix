#=====================================================================#
# COSMIC PANEL APPLETS AND DESKTOP TOOLING
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Third-Party Panel Applets
  #--------------------------------------------------------------------#
  # Settings are GUI-managed, not declared. minimon in the panel uses the
  # component ID io.github.cosmic_utils.minimon-applet-panel and persists
  # full structs per sensor, so a partial declaration would reset the rest.
  home.packages = with pkgs; [
    cosmic-ext-applet-minimon # CPU / memory / GPU / temps / network / disk
    cosmic-ext-applet-privacy-indicator # Mic / camera / screen share
    cosmic-ext-applet-caffeine # Idle inhibitor

    #--------------------------------------------------------------------#
    #-- Desktop Tooling
    #--------------------------------------------------------------------#
    cosmic-ext-tweaks # Panel/dock/theme knobs the Settings app omits
    examine # System information viewer
  ];
}
