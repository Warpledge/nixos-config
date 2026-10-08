#=====================================================================#
# MPV MEDIA PLAYER CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Configuration
  #--------------------------------------------------------------------#

  programs.mpv = {
    enable = true;
    defaultProfiles = ["gpu-hq"];
    scripts = with pkgs.mpvScripts; [
      mpris
      uosc # Replaces the stock OSC, hence osc = "no" below
    ];
    config = {
      volume = 100;
      volume-max = 200;
      osd-bar = "no";
      osc = "no";
    };
  };
}
