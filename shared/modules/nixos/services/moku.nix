#=====================================================================#
# MOKU (FLATPAK)
#=====================================================================#
#- Manga, light novel and anime app. Not on Flathub, so the release's
#- Flatpak bundle is installed from the store; its GNOME 48 runtime and
#- ffmpeg-full extension come from Flathub. Library and settings live in
#- ~/.var/app/io.github.MokuProject.Moku.
{pkgs, ...}: let
  version = "0.13.1";
  hash = "sha256-NyudchJydsLDvYtDg3iedSnBIehBXdT8e9nH7NTmRcw=";

  bundle = pkgs.fetchurl {
    url = "https://github.com/moku-project/Moku/releases/download/v${version}/Moku-${version}.flatpak";
    name = "io.github.MokuProject.Moku.flatpak";
    inherit hash;
  };
in {
  #--------------------------------------------------------------------#
  #-- Moku
  #--------------------------------------------------------------------#
  services.flatpak = {
    packages = [
      {
        appId = "io.github.MokuProject.Moku";
        bundle = "${bundle}";
        sha256 = hash; # nix-flatpak reinstalls when this changes
      }
    ];

    #--- The bundle requests no audio socket, so videos would play silently
    overrides."io.github.MokuProject.Moku".Context.sockets = ["pulseaudio"];
  };
}
