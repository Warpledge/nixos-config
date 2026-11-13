#=====================================================================#
# KYLERJ'S APPS
#=====================================================================#
#- Apps with no switch in users/_template/settings.nix. Everything else Ky
#- installs from the Apps window into the user profile and keeps in
#- packages.json, so an update can't break the build on a package name.
#- Emulators, the Epic launcher and other AppImages are kept by hand (Gear
#- Lever), RetroDECK through Flatpak.
{
  lib,
  pkgs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  #--- Vivaldi stays declared: the default browser below names its desktop
  #--- file, which a profile install only provides once it is installed
  home.packages = with pkgs; [vivaldi];

  #--- Easy Effects runs in the background from login
  services.easyeffects.enable = true;

  #--------------------------------------------------------------------#
  #-- Default Browser
  #--------------------------------------------------------------------#
  #--- Vivaldi isn't one of lib/default-apps.nix's choices, so it's set here
  xdg.mimeApps.defaultApplications = lib.genAttrs [
    "text/html"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ] (_: lib.mkForce ["vivaldi-stable.desktop"]);
}
