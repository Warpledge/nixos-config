#=====================================================================#
# TOBIRA NO DENSETSU
#=====================================================================#
#- RPG Maker 2000 game (English patch) run on native EasyRPG in gamescope
#- at 320x240, starting on sharp bilinear (Super+H cycles the others). The
#- game folder is kept outside the repo.
{pkgs, ...}: let
  gameDir = "/mnt/games/Visual Novels/+RPGM/Tobira no Densetsu English/Tobiden";

  #--- Extracted from RPG_RT.exe (wrestool + icotool, icoutils)
  icon = "/mnt/games/Visual Novels/+RPGM/Tobira no Densetsu English/icon.png";

  #--- Fullscreen makes EasyRPG fill gamescope's 320x240 instead of a scaled window
  tobira-no-densetsu =
    pkgs.writeShellScriptBin "tobira-no-densetsu"
    # bash
    ''
      exec nix-gamescope -w 320 -h 240 -F sharpbilinear -- \
        easyrpg-player --fullscreen --project-path "${gameDir}" \
        --font2 "$HOME/.config/EasyRPG/Player/Font/NotoSans-Regular.ttf" "$@"
    '';
in {
  #--------------------------------------------------------------------#
  #-- Launcher
  #--------------------------------------------------------------------#
  home.packages = [tobira-no-densetsu];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.tobira-no-densetsu = {
    name = "Tobira no Densetsu";
    exec = "tobira-no-densetsu";
    inherit icon;
    terminal = false;
    categories = ["Game"];
  };
}
