#=====================================================================#
# MPV MEDIA PLAYER CONFIGURATION
#=====================================================================#
{
  lib,
  pkgs,
  ...
}: let
  #--- Anime4K mode: shader names in order, as upstream's high-end GPU template
  anime4k = label: shaders: let
    files = map (s: "${pkgs.anime4k}/Anime4K_${s}.glsl") shaders;
  in ''no-osd change-list glsl-shaders set "${lib.concatStringsSep ":" files}"; show-text "Anime4K: ${label}"'';
in {
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

    #--- Anime4K shaders, off until a key picks a mode. A, B and C suit 1080p,
    #--- 720p and 480p sources; the doubled modes add a second restore pass
    bindings = {
      "CTRL+1" = anime4k "Mode A (HQ)" [
        "Clamp_Highlights"
        "Restore_CNN_VL"
        "Upscale_CNN_x2_VL"
        "AutoDownscalePre_x2"
        "AutoDownscalePre_x4"
        "Upscale_CNN_x2_M"
      ];
      "CTRL+2" = anime4k "Mode B (HQ)" [
        "Clamp_Highlights"
        "Restore_CNN_Soft_VL"
        "Upscale_CNN_x2_VL"
        "AutoDownscalePre_x2"
        "AutoDownscalePre_x4"
        "Upscale_CNN_x2_M"
      ];
      "CTRL+3" = anime4k "Mode C (HQ)" [
        "Clamp_Highlights"
        "Upscale_Denoise_CNN_x2_VL"
        "AutoDownscalePre_x2"
        "AutoDownscalePre_x4"
        "Upscale_CNN_x2_M"
      ];
      "CTRL+4" = anime4k "Mode A+A (HQ)" [
        "Clamp_Highlights"
        "Restore_CNN_VL"
        "Upscale_CNN_x2_VL"
        "Restore_CNN_M"
        "AutoDownscalePre_x2"
        "AutoDownscalePre_x4"
        "Upscale_CNN_x2_M"
      ];
      "CTRL+5" = anime4k "Mode B+B (HQ)" [
        "Clamp_Highlights"
        "Restore_CNN_Soft_VL"
        "Upscale_CNN_x2_VL"
        "AutoDownscalePre_x2"
        "AutoDownscalePre_x4"
        "Restore_CNN_Soft_M"
        "Upscale_CNN_x2_M"
      ];
      "CTRL+6" = anime4k "Mode C+A (HQ)" [
        "Clamp_Highlights"
        "Upscale_Denoise_CNN_x2_VL"
        "AutoDownscalePre_x2"
        "AutoDownscalePre_x4"
        "Restore_CNN_M"
        "Upscale_CNN_x2_M"
      ];
      "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "Anime4K: off"'';
    };
  };
}
