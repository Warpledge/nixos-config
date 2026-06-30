#=====================================================================#
# DISCORD CONFIGURATION (NIXCORD)
#=====================================================================#
{inputs, ...}: {
  imports = [inputs.nixcord.homeModules.nixcord];

  #--------------------------------------------------------------------#
  #-- Settings
  #--------------------------------------------------------------------#
  #- https://kaylorben.github.io/nixcord/
  programs.nixcord = {
    enable = true;
    discord.enable = false; # disable default Discord, use Vesktop instead
    vesktop.enable = true;
    config = {
      frameless = true; # set some Vencord options
      plugins = {
        biggerStreamPreview.enable = true;
        fakeNitro.enable = true;
        fixImagesQuality.enable = true;
        fixSpotifyEmbeds.enable = true;
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        fullSearchContext.enable = true;
        imageZoom.enable = true;
        memberCount.enable = true;
        noProfileThemes.enable = true;
        noTypingAnimation.enable = true;
        silentTyping.enable = true;
        spotifyCrack.enable = true;
        unlockedAvatarZoom.enable = true;
        viewIcons.enable = true;
        volumeBooster.enable = true;
        webRichPresence.enable = true; # WebRichPresence (arRPC): read game presence from standalone arRPC service
        youtubeAdblock.enable = true;
        messageClickActions = {
          enable = true;
          enableDeleteOnClick = true; # Hold Backspace + click to delete (default: true)
          enableDoubleClickToEdit = true; # Double-click to edit (default: true)
          enableDoubleClickToReply = true; # Double-click to reply (default: true)
          requireModifier = false; # No need for Shift/Ctrl on double-click (default: false)
        };
      };
    };
  };
}
