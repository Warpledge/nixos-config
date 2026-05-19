#=====================================================================#
# SUNSHINE GAME STREAM HOST (MOONLIGHT)
#=====================================================================#
_: {
  #--------------------------------------------------------------------#
  #-- Sunshine Service
  #--------------------------------------------------------------------#
  services.sunshine = {
    enable = true;
    autoStart = true;
    # CAP_SYS_ADMIN required for KMS/DRM screen capture on Wayland
    capSysAdmin = true;
    openFirewall = true;
  };
}
