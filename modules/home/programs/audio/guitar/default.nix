#=====================================================================#
# GUITAR AMP MODELING CONFIGURATION
#=====================================================================#
{
  pkgs,
  config,
  lib,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Plugin Packages
  #--------------------------------------------------------------------#
  # Shared by every guitar toggle; this folder loads when any one is on.

  home.packages = with pkgs; [
    #--- Cabinet impulse responses and utility processing
    ir-lv2 # Convolution IR loader
    x42-plugins # Includes x42-tuner
    lsp-plugins

    #--- Patchbay for wiring DI -> plugin -> monitoring
    qpwgraph
  ];

  #--------------------------------------------------------------------#
  #-- Plugin Discovery
  #--------------------------------------------------------------------#
  # Hosts scan fixed paths and do not know about the home-manager
  # profile, so point them at it explicitly.

  home.sessionVariables = let
    profile = config.home.profileDirectory;
  in {
    LV2_PATH = "${profile}/lib/lv2";
    CLAP_PATH = "${profile}/lib/clap";
    VST3_PATH = "${profile}/lib/vst3";
  };

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    lib.optionals hostConfig.audio.guitarix [./guitarix.nix]
    ++ lib.optionals hostConfig.audio.tone3000 [./tone3000.nix]
    ++ lib.optionals hostConfig.audio.katanaFloorboard [./katana-floorboard.nix];
}
