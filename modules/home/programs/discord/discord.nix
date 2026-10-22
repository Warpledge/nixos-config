#=====================================================================#
# DISCORD CONFIGURATION (NIXCORD)
#=====================================================================#
{
  config,
  options,
  inputs,
  ...
}: let
  inherit (config.lib.stylix.colors) base00-rgb-r base00-rgb-g base00-rgb-b;
in {
  imports = [inputs.nixcord.homeModules.nixcord];

  #--- GoofCord loads assets/Themes.css at start: DMS's Discord template fills it on
  #--- each theme change (theme/matugen.nix) instead of nixcord's copy
  home.file."${config.xdg.configHome}/goofcord/GoofCord/assets/Themes.css".enable = false;
  matugen.templates.goofcord = {
    input = "${inputs.dms}/quickshell/matugen/templates/vesktop.css";
    output = "${config.xdg.configHome}/goofcord/GoofCord/assets/Themes.css";
  };

  #--------------------------------------------------------------------#
  #-- Settings
  #--------------------------------------------------------------------#
  #- https://kaylorben.github.io/nixcord/
  programs.nixcord = {
    enable = true;
    #--- GoofCord asserts nixcord's pinned Node version, which our nixpkgs lacks
    useGlobalPkgs = false;
    discord.enable = false; # disable default Discord, use GoofCord instead
    vesktop.enable = false; # replaced by GoofCord
    #--- arRPC is off by default: the standalone arrpc service owns port 1337
    goofcord.enable = true;
    #--- Electron can't map XDG_CURRENT_DESKTOP=niri to a keyring and falls back
    #--- to plain text; point safeStorage at gnome-keyring's Secret Service
    goofcord.package = options.programs.nixcord.goofcord.package.default.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          wrapProgramShell $out/bin/goofcord --add-flags "--password-store=gnome-libsecret"
        '';
    });
    #--- Written wholesale to settings.json on every activation, like vesktop.settings
    #--- Reports the OS as Windows so Discord accepts logins over the VPN
    goofcord.settings.spoofWindows = true;

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
      splashBackground = "rgb(${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b})";
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
        # WebRichPresence (arRPC): read game presence from standalone arRPC service
        webRichPresence.enable = true;
        youtubeAdblock.enable = true;
        messageClickActions = {
          enable = true;
          enableDeleteOnClick = true; # Hold Backspace + click to delete (default: true)
          enableDoubleClickToEdit = true; # Double-click to edit (default: true)
          enableDoubleClickToReply = true; # Double-click to reply (default: true)
          requireModifier = false; # Double-click without Shift/Ctrl (default)
        };
      };
    };
  };
}
