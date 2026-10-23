#=====================================================================#
# GUITARIX (PIPEWIRE JACK, X11 BACKEND)
#=====================================================================#
{pkgs, ...}: let
  #--- PipeWire's libjack makes it a real JACK client that follows the graph
  #--- buffer; upstream's libjack2 falls back to ALSA at a fixed 256-frame
  #--- period or asks for a JACK server. PIPEWIRE_LATENCY is read once at
  #--- startup, since changing a live client's buffer deadlocks it.
  #--- X11 backend: its GTK3 window can't be resized under Wayland.
  #--- postFixup, since wrap-gapps-hook wraps the binary during fixupPhase.
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
  #-- Package
  #--------------------------------------------------------------------#
  #--- Modular amp rig; NAM loader modules since 0.45.
  home.packages = [guitarix];
}
