#=====================================================================#
# KATANA MK2 FXFLOORBOARD CONFIGURATION
#=====================================================================#
#- Patch editor for the Boss Katana MK2 amp (Colin Willcocks' tool).
#- Not in nixpkgs; this wraps the prebuilt Linux bundle that lives at
#- ~/.local/opt/katana-fxfloorboard/ (kept out of the public repo).
#-
#- The bundle ships its own libraries (RUNPATH -> ./lib) and runs via
#- nix-ld; the only thing it needs from us is ALSA_CONFIG_PATH so the
#- RtMidi/ALSA sequencer can find its config and reach the amp.
{pkgs, ...}: let
  #-- Stable install location for the prebuilt bundle
  appDir = "$HOME/.local/opt/katana-fxfloorboard";

  #-- Wrapper: set ALSA config path, then exec the bundled binary
  katana-fxfloorboard =
    pkgs.writeShellScriptBin "katana-fxfloorboard"
    ''
      export ALSA_CONFIG_PATH="${pkgs.alsa-lib}/share/alsa/alsa.conf"
      exec "${appDir}/Katana-MK2-FxFloorBoard" "$@"
    '';
in {
  #--------------------------------------------------------------------#
  #-- Wrapper Package
  #--------------------------------------------------------------------#
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
