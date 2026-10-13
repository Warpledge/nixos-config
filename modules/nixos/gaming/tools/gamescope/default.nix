#=====================================================================#
# GAMESCOPE COMPOSITOR
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Gamescope
  #--------------------------------------------------------------------#
  programs.gamescope = {
    enable = true;
    #--- Adds `-F xbr` (Super+H toggles it): Super-xBR 2x, shaders from libretro.
    #--- The patch is written against the nixpkgs version; a bump may need it redone
    package = pkgs.gamescope.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./super-xbr.patch];
      #--- The toggle's on/off notification
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace src/main.cpp \
            --replace-fail "@notifySend@" "${pkgs.libnotify}/bin/notify-send"
        '';
    });
    capSysNice = false;
    args = [
      "--rt" # Realtime scheduling support
      "--expose-wayland" # Expose Wayland socket for native games
    ];
  };
}
