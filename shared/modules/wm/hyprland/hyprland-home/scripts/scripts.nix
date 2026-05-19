#=====================================================================#
# HYPRLAND CUSTOM SCRIPTS
#=====================================================================#
# @FrostPhoenix (edited)
{pkgs, ...}: let
  toggle_opacity = pkgs.writeScriptBin "toggle_opacity" (
    builtins.readFile ./scripts/toggle_opacity.sh
  );
  toggle_blur = pkgs.writeScriptBin "toggle_blur" (
    builtins.readFile ./scripts/toggle_blur.sh
  );
  toggle_float = pkgs.writeScriptBin "toggle_float" (
    builtins.readFile ./scripts/toggle_float.sh
  );
  toggle_hdr = pkgs.writeScriptBin "toggle_hdr" (
    builtins.readFile ./scripts/toggle_hdr.sh
  );
in {
  #--------------------------------------------------------------------#
  #-- Custom Script Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    #--- Custom Scripts (@FrostPhoenix)
    toggle_opacity
    toggle_blur
    toggle_float
    toggle_hdr
  ];
}
