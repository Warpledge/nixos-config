#=====================================================================#
# REAPER DAW CONFIGURATION
#=====================================================================#
{pkgs, ...}: let
  #--- Point Reaper's JACK backend at PipeWire's libjack so the JACK
  #--- device works without services.pipewire.jack or a standalone jackd
  reaper = pkgs.reaper.override {jackLibrary = pkgs.pipewire.jack;};
in {
  #--------------------------------------------------------------------#
  #-- Reaper Package
  #--------------------------------------------------------------------#

  home.packages = [reaper];

  #--------------------------------------------------------------------#
  #-- Extensions
  #--------------------------------------------------------------------#
  # Reaper loads native extensions from its resource dir (~/.config/REAPER).
  # Link the files individually, not the directories, so ReaPack can still
  # write its own downloads alongside them.

  xdg.configFile = {
    #--- SWS / S&M: actions, cursors and track tools
    "REAPER/UserPlugins/reaper_sws-x86_64.so".source = "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so";
    "REAPER/Scripts/sws_python.py".source = "${pkgs.reaper-sws-extension}/Scripts/sws_python.py";
    "REAPER/Scripts/sws_python64.py".source = "${pkgs.reaper-sws-extension}/Scripts/sws_python64.py";

    #--- ReaPack: in-app package manager for scripts and JSFX
    "REAPER/UserPlugins/reaper_reapack-x86_64.so".source = "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so";
  };
}
