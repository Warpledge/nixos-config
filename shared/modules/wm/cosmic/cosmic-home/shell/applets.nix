#=====================================================================#
# COSMIC PANEL APPLETS AND DESKTOP TOOLING
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Third-Party Panel Applets
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    #--- io.github.cosmic_utils.minimon-applet
    # CPU / memory / GPU / VRAM / CPU+GPU temperature / network / disk, with
    # ring, line, heat and stacked-bar chart styles.
    cosmic-ext-applet-minimon

    #--- dev.DBrox.CosmicPrivacyIndicator
    # DMS showPrivacyButton equivalent (mic / camera / screen share)
    cosmic-ext-applet-privacy-indicator

    #--- net.tropicbliss.CosmicExtAppletCaffeine
    # DMS idleInhibitor control-center tile equivalent
    cosmic-ext-applet-caffeine

    #--------------------------------------------------------------------#
    #-- Desktop Tooling
    #--------------------------------------------------------------------#
    cosmic-ext-tweaks # Panel/dock/theme knobs the Settings app omits
    examine # System information viewer
  ];
}
