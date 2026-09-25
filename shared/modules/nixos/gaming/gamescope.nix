#=====================================================================#
# GAMESCOPE COMPOSITOR
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Gamescope
  #--------------------------------------------------------------------#
  programs.gamescope = {
    enable = true;
    capSysNice = false;
    args = [
      "--rt" # Realtime scheduling support
      "--expose-wayland" # Expose Wayland socket for native games
    ];
  };
}
