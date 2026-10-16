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
  #--- ArtCNN C4F32, an anime-trained luma doubler; not in nixpkgs
  artcnn = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Artoriuz/ArtCNN/a1b6ace035df4a9e9a113713dd7ee4eb92dd67ea/GLSL/ArtCNN_C4F32.glsl";
    hash = "sha256-93O85s9f5+Xl1Zmmle3UDfXNeiDD0IxNFk0HWR1b6tM=";
  };
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
      thumbfast # Seek-bar thumbnails in uosc
      eisa01.smartskip # Auto-skips OP, ED and preview chapters; Ctrl+. toggles
    ];
    config = {
      volume = 100;
      volume-max = 200;
      osd-bar = "no";
      osc = "no";
      deband = "yes"; # The high-quality profile leaves banding in 8-bit encodes
      #--- Japanese audio and English subs on dual-audio releases
      alang = "jpn,ja";
      slang = "eng,en";
      #--- 23.976 fps doesn't divide 280 Hz, so frames are blended to stop judder
      video-sync = "display-resample";
      interpolation = "yes";
    };

    #--- Anime4K shaders, off until a key picks a mode. A, B and C suit 1080p,
    #--- 720p and 480p sources; the doubled modes add a second restore pass.
    #--- Ctrl+7 swaps in ArtCNN instead, and Ctrl+0 clears either
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
      "CTRL+7" = ''no-osd change-list glsl-shaders set "${artcnn}"; show-text "ArtCNN: C4F32"'';
      "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "Shaders: off"'';
    };
  };
}
