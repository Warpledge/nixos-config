#=====================================================================#
# EASYRPG PLAYER
#=====================================================================#
#- Interpreter for RPG Maker 2000/2003 and EasyRPG games; point it at a
#- game directory rather than installing per-game.
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [pkgs.easyrpg-player];
}
