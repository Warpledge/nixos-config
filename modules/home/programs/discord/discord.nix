#=====================================================================#
# DISCORD CONFIGURATION (NIXCORD)
#=====================================================================#
{
  config,
  options,
  inputs,
  lib,
  user,
  ...
}: let
  inherit (config.lib.stylix.colors) base00-rgb-r base00-rgb-g base00-rgb-b;
  #--- Electron can't map XDG_CURRENT_DESKTOP=niri to a keyring and falls back
  #--- to plain text; point safeStorage at gnome-keyring's Secret Service
  keyring = "--password-store=gnome-libsecret";
in {
  imports = [inputs.nixcord.homeModules.nixcord];

  #--- GoofCord loads assets/Themes.css at start: DMS's Discord template fills it on
  #--- each theme change (theme/matugen.nix) instead of nixcord's copy
  home.file = lib.mkIf user.discord.goofcord {
    "${config.xdg.configHome}/goofcord/GoofCord/assets/Themes.css".enable = false;
  };
  matugen.templates = lib.mkIf user.discord.goofcord {
    goofcord = {
      input = "${inputs.dms}/quickshell/matugen/templates/vesktop.css";
      output = "${config.xdg.configHome}/goofcord/GoofCord/assets/Themes.css";
    };
  };

  #--------------------------------------------------------------------#
  #-- Settings
  #--------------------------------------------------------------------#
  #- https://kaylorben.github.io/nixcord/
  programs.nixcord = {
    enable = true;
    #--- GoofCord asserts nixcord's pinned Node version, which our nixpkgs lacks
    useGlobalPkgs = false;
    discord.enable = false; # disable default Discord, use GoofCord or Vesktop instead
    #--- arRPC is off by default: the standalone arrpc service owns port 1337
    goofcord.enable = user.discord.goofcord;
    goofcord.package = options.programs.nixcord.goofcord.package.default.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          wrapProgramShell $out/bin/goofcord --add-flags "${keyring}"
        '';
    });
    #--- DMS's built-in Vesktop template writes themes/dank-discord.css, which
    #--- Vencord reloads live (enabledThemes below)
    vesktop.enable = user.discord.vesktop;
    vesktop.package = options.programs.nixcord.vesktop.package.default.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram $out/bin/vesktop --add-flags "${keyring}"
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
    #--- QuickCSS hides the reaction pills; superReactionTweaks stops their bursts
    quickCss = lib.mkIf user.discord.hideReactions ''
      [class^="reactions_"], [class*=" reactions_"] {
        display: none !important;
      }
    '';
    config = {
      frameless = true; # set some Vencord options
      enabledThemes = lib.optionals user.discord.vesktop ["dank-discord.css"];
      useQuickCss = user.discord.hideReactions;
      plugins = {
        biggerStreamPreview.enable = user.discord.plugins.biggerStreamPreview;
        fakeNitro.enable = user.discord.plugins.fakeNitro;
        fixImagesQuality.enable = user.discord.plugins.fixImagesQuality;
        fixSpotifyEmbeds.enable = user.discord.plugins.fixSpotifyEmbeds;
        fixYoutubeEmbeds.enable = user.discord.plugins.fixYoutubeEmbeds;
        forceOwnerCrown.enable = user.discord.plugins.forceOwnerCrown;
        fullSearchContext.enable = user.discord.plugins.fullSearchContext;
        imageZoom.enable = user.discord.plugins.imageZoom;
        memberCount.enable = user.discord.plugins.memberCount;
        messageClickActions = {
          enable = user.discord.plugins.messageClickActions;
          enableDeleteOnClick = true; # Hold Backspace + click to delete (default: true)
          enableDoubleClickToEdit = true; # Double-click to edit (default: true)
          enableDoubleClickToReply = true; # Double-click to reply (default: true)
          requireModifier = false; # Double-click without Shift/Ctrl (default)
        };
        noProfileThemes.enable = user.discord.plugins.noProfileThemes;
        noTypingAnimation.enable = user.discord.plugins.noTypingAnimation;
        silentTyping.enable = user.discord.plugins.silentTyping;
        spotifyCrack.enable = user.discord.plugins.spotifyCrack;
        superReactionTweaks = {
          enable = user.discord.plugins.superReactionTweaks;
          superReactionPlayingLimit = 0.0; # No super reaction animations
          superReactByDefault = false;
        };
        unlockedAvatarZoom.enable = user.discord.plugins.unlockedAvatarZoom;
        viewIcons.enable = user.discord.plugins.viewIcons;
        volumeBooster.enable = user.discord.plugins.volumeBooster;
        # WebRichPresence (arRPC): read game presence from standalone arRPC service
        webRichPresence.enable = user.discord.plugins.webRichPresence;
        youtubeAdblock.enable = user.discord.plugins.youtubeAdblock;
      };
    };
  };
}
