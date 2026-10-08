#=====================================================================#
# GUITARIX (PIPEWIRE JACK, X11 BACKEND)
#=====================================================================#
{pkgs, ...}: let
  #--- Upstream links against libjack2; with no JACK server answering it falls
  #--- back to ALSA at a fixed 256 frame period, which no graph setting can
  #--- reach. PipeWire's libjack makes it a real JACK client, so it follows the
  #--- graph buffer and handles buffer changes through the JACK callback.
  #--- PIPEWIRE_LATENCY is read once at startup: changing the buffer on a live
  #--- client deadlocks it, so it is set here rather than via pw-metadata.
  #--- guitarix is JACK-only, so without it the app
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
  #-- Package
  #--------------------------------------------------------------------#
  #--- Modular amp rig; NAM loader modules since 0.45.
  home.packages = [guitarix];
}
