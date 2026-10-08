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

    #--- Written wholesale to ~/.config/vesktop/settings.json (a copy, not a
    #--- merge), so every key must be declared or it is dropped.
    #--- arRPC stays false: the standalone arrpc service owns port 1337.
    vesktop.settings = {
      discordBranch = "stable";
      minimizeToTray = true;
      arRPC = false;
      hardwareVideoAcceleration = true;
      disableSmoothScroll = false;
      customTitleBar = false;
      staticTitle = false;
      enableMenu = false;
      tray = true;
      splashColor = "rgb(239, 239, 241)";
      splashBackground = "rgb(30, 30, 46)";
      spellCheckLanguages = ["en-US" "en"];
    };
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
