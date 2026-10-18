{
  config,
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
    colorScheme = lib.mkForce "custom";
    # The theme's [mocha] colours, with Stylix's base00 as main in place of Base
    customColorScheme = {
      text = "cdd6f4";
      subtext = "cdd6f4";
      main = config.lib.stylix.colors.base00;
      main-elevated = "313244";
      highlight = "313344";
      highlight-elevated = "45475a";
      sidebar = "181825";
      player = "11111b";
      card = "313244";
      shadow = "181825";
      selected-row = "9399b2";
      button = "7f849c";
      button-active = "9399b2";
      button-disabled = "6c7086";
      tab-active = "313244";
      notification = "313244";
      notification-error = "f38ba8";
      equalizer = "000000";
      misc = "45475a";
    };

    #--- https://github.com/Gerg-L/spicetify-nix/tree/master/docs
    enabledExtensions = with spicePkgs.extensions; [
      # autoSkipVideo
      # playlistIcons
      # popupLyrics
      # hidePodcasts
      adblock
      # loopyLoop
      # seekSong
      # goToSong
      # betterGenres — dropped from spicetify-nix upstream, 2026-09-23
      playingSource
    ];
  };
}
