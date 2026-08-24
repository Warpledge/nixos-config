#=====================================================================#
# GUITAR AMP MODELING CONFIGURATION
#=====================================================================#
{
  pkgs,
  config,
  ...
}: let
  #--- Upstream links against libjack2; with no JACK server answering it falls
  #--- back to ALSA at a fixed 256 frame period, which no graph setting can
  #--- reach. PipeWire's libjack makes it a real JACK client, so it follows the
  #--- graph buffer and handles buffer changes through the JACK callback.
  #--- PIPEWIRE_LATENCY is read once at startup: changing the buffer on a live
  #--- client deadlocks it, so it is set here rather than via pw-metadata.
  #--- pipewire.jack ships no headers, so the build keeps libjack2 and the
  #--- swap happens at runtime: the binary uses RUNPATH, which LD_LIBRARY_PATH
  #--- overrides. Wrapping the binary rather than adding a launcher command
  #--- means the desktop entry (Exec=Neuralrack) picks this up too.
  neuralrack = pkgs.neuralrack.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
    postInstall =
      (old.postInstall or "")
      + ''
        wrapProgram $out/bin/Neuralrack \
          --prefix LD_LIBRARY_PATH : ${pkgs.pipewire.jack}/lib \
          --set-default PIPEWIRE_LATENCY 128/48000
      '';
  });

  #--- Same libjack redirect; guitarix is JACK-only, so without it the app
  #--- opens a "jack server is not running" prompt instead of starting.
  #--- Its GTK3 UI builds degenerate under Wayland (a 792x168 window that
  #--- refuses compositor resize), so pin the X11 backend. postFixup, not
  #--- postInstall: wrap-gapps-hook wraps the binary during fixupPhase.
  guitarix = pkgs.guitarix.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
    postFixup =
      (old.postFixup or "")
      + ''
        wrapProgram $out/bin/guitarix \
          --prefix LD_LIBRARY_PATH : ${pkgs.pipewire.jack}/lib \
          --set-default GDK_BACKEND x11 \
          --set-default PIPEWIRE_LATENCY 128/48000
      '';
  });
in {
  #--------------------------------------------------------------------#
  #-- Amp Sim and Plugin Packages
  #--------------------------------------------------------------------#

  home.packages = with pkgs; [
    #--- Neural amp modeling: loads .nam/.json/.aidax captures.
    #--- Ships a standalone binary plus LV2/CLAP/VST2/VST3.
    neuralrack
    neural-amp-modeler-lv2

    #--- Blends two NAM/AIDA-X profiles for roughly one profile's CPU cost.
    ratatouille-lv2

    #--- Modular amp rig; NAM loader modules since 0.45.
    guitarix

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
}
