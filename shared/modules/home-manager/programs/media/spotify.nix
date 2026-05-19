{
  pkgs,
  lib,
  inputs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  #=====================================================================#
  # SPOTIFY CONFIGURATION
  #=====================================================================#

  imports = [inputs.spicetify-nix.homeManagerModules.default];

  #--------------------------------------------------------------------#
  #-- Settings
  #--------------------------------------------------------------------#

  programs.spicetify = {
    enable = true;
    theme = lib.mkForce spicePkgs.themes.catppuccin;
    colorScheme = lib.mkForce "mocha";
    # theme = lib.mkForce spicePkgs.themes.lucid;

    #--- https://github.com/Gerg-L/spicetify-nix/tree/master/docs
    enabledExtensions = with spicePkgs.extensions; [
      autoSkipVideo
      playlistIcons
      popupLyrics
      hidePodcasts
      adblock
      loopyLoop
      seekSong
      goToSong
      betterGenres
      playingSource
    ];
  };
}
