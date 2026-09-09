#=====================================================================#
# NIRI XDG PORTAL BACKENDS
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Portal Backends
  #--------------------------------------------------------------------#
  # niri-flake's home module points NIX_XDG_DESKTOP_PORTAL_DIR at the user
  # profile and puts only gnome.portal there, so the gtk backend that
  # niri-portals.conf routes Access and Notification to is invisible.
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
}
