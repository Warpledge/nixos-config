#=====================================================================#
# GAMESCOPE COMPOSITOR
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Gamescope
  #--------------------------------------------------------------------#
  programs.gamescope = {
    enable = true;
    #--- Adds `-F anime4k` (Anime4K CNN x2 M, converted by anime4k-convert.py),
    #--- `-F nvl` (NVL CNN 4x16, converted by nvl-convert.py), `-F mmpx` and
    #--- `-F sharpbilinear`. Super+H cycles them and linear, starting from the
    #--- `-F` one (NVL otherwise). The patches apply in order against the nixpkgs
    #--- version; a bump may need them redone
    package = pkgs.gamescope.overrideAttrs (old: {
      patches =
        (old.patches or [])
        ++ [./anime4k.patch ./nvl.patch ./pixel-art.patch];
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
