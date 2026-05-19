#=====================================================================#
# WAYLAND CONFIGURATION (XWAYLAND, XDG PORTAL)
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: {
  #--- XWayland Compatibility
  programs.xwayland.enable = true; # Enable X11 applications on Wayland

  #--------------------------------------------------------------------#
  #-- XDG Portal Configuration
  #--------------------------------------------------------------------#
  xdg.portal = {
    enable = true; # Enable XDG portal for desktop integration
    xdgOpenUsePortal = true; # Use portal for xdg-open operations
    extraPortals = lib.mkDefault [
      pkgs.xdg-desktop-portal-gtk # GTK file picker and dialogs
    ];
    config.common.default = lib.mkDefault "*"; # Use any available portal backend
  };

  #--------------------------------------------------------------------#
  #-- System Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    shared-mime-info # MIME type database for file associations
  ];
}
