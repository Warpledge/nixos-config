#=====================================================================#
# KATANA MK2 FXFLOORBOARD (AMP PATCH EDITOR)
#=====================================================================#
{pkgs, ...}: let
  #--- Patch editor for the amp itself (Colin Willcocks' tool), not in nixpkgs.
  #--- Prebuilt bundle under ~/.local/opt, kept out of git and restored by hand;
  #--- see docs/local/local-binary-installs.md. It ships its own libs
  #--- (RUNPATH -> ./lib) and runs via nix-ld, so the only thing it needs is
  #--- ALSA_CONFIG_PATH for RtMidi to reach the amp over the ALSA sequencer.
  katanaDir = "$HOME/.local/opt/katana-fxfloorboard";
  katana-fxfloorboard =
    pkgs.writeShellScriptBin "katana-fxfloorboard"
    ''
      export ALSA_CONFIG_PATH="${pkgs.alsa-lib}/share/alsa/alsa.conf"
      # Writes assign.kat, license.txt and preferences.xml into its working directory
      cd "${katanaDir}"
      exec "${katanaDir}/Katana-MK2-FxFloorBoard" "$@"
    '';
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  #--- Amp patch editor (prebuilt bundle, see above)
  home.packages = [katana-fxfloorboard];

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
}
