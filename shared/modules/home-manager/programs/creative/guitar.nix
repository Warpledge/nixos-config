#=====================================================================#
# GUITAR AMP MODELING CONFIGURATION
#=====================================================================#
{
  pkgs,
  lib,
  config,
  ...
}: let
  #--- Neuralrack never auto-connects: connectPorts() only replays [Connection]
  #--- lines from ~/.config/neuralrack.conf, so a fresh profile comes up with an
  #--- unwired node and no sound. Wire the graph here instead of depending on a
  #--- file the app rewrites on exit. Endpoints are resolved at runtime so both
  #--- hosts share this. `in` is a MIDI port; the audio input is `in_0`.
  neuralrack-autolink = pkgs.writeShellScript "neuralrack-autolink" ''
    export PATH=${lib.makeBinPath [pkgs.pipewire pkgs.wireplumber pkgs.gnugrep pkgs.gnused pkgs.coreutils]}

    #--- Ports register a moment after the JACK client opens.
    for _ in $(seq 100); do
      pw-link -i 2>/dev/null | grep -qx 'neuralrack:in_0' && break
      sleep 0.1
    done

    di=$(pw-link -o 2>/dev/null |
      grep -m1 -E '^alsa_input\..*KATANA.*Line4__source:capture_FL$')
    sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null |
      sed -n 's/.*node\.name = "\([^"]*\)".*/\1/p')

    #--- Re-linking an already-connected pair errors; the app replays its own
    #--- saved connections too, so treat every link as best-effort.
    if [ -n "$di" ]; then
      pw-link "$di" neuralrack:in_0 || true
    fi

    if [ -n "$sink" ]; then
      pw-link neuralrack:out_0 "$sink:playback_FL" || true
      pw-link neuralrack:out_1 "$sink:playback_FR" || true
    fi
  '';

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
          --set-default PIPEWIRE_LATENCY 128/48000 \
          --run ${lib.escapeShellArg "${neuralrack-autolink} &"}
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

  #--- Patch editor for the amp itself (Colin Willcocks' tool), not in nixpkgs.
  #--- Prebuilt bundle under ~/.local/opt, kept out of git and restored by hand;
  #--- see .notes/local/local-binary-installs.md. It ships its own libs
  #--- (RUNPATH -> ./lib) and runs via nix-ld, so the only thing it needs is
  #--- ALSA_CONFIG_PATH for RtMidi to reach the amp over the ALSA sequencer.
  katanaDir = "$HOME/.local/opt/katana-fxfloorboard";
  katana-fxfloorboard =
    pkgs.writeShellScriptBin "katana-fxfloorboard"
    ''
      export ALSA_CONFIG_PATH="${pkgs.alsa-lib}/share/alsa/alsa.conf"
      exec "${katanaDir}/Katana-MK2-FxFloorBoard" "$@"
    '';
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

    #--- Amp patch editor (prebuilt bundle, see above)
    katana-fxfloorboard
  ];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#

  xdg.desktopEntries.katana-fxfloorboard = {
    name = "Katana MK2 FxFloorBoard";
    comment = "Patch editor for the Boss Katana MK2 amp";
    exec = "katana-fxfloorboard";
    icon = "audio-card";
    terminal = false;
    categories = ["Audio" "AudioVideo" "Music"];
  };

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
