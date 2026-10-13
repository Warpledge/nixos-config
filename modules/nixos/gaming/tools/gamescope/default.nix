#=====================================================================#
# GAMESCOPE COMPOSITOR
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Gamescope
  #--------------------------------------------------------------------#
  programs.gamescope = {
    enable = true;
    #--- Adds `-F xbr` (Super-xBR 2x, shaders from libretro) and `-F anime4k`
    #--- (Anime4K CNN x2 M, converted by anime4k-convert.py). Super+H cycles them
    #--- and linear, starting from Anime4K unless `-F xbr`. The patches apply in
    #--- order against the nixpkgs version; a bump may need them redone
    package = pkgs.gamescope.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./super-xbr.patch ./anime4k.patch];
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
