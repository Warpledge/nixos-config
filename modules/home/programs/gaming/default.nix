#=====================================================================#
# GAMING ENVIRONMENT CONFIGURATION
#=====================================================================#
#- `user` comes in through `import ./gaming user` (programs/default.nix),
#- since the imports below read it
user: {
  pkgs,
  config,
  lib,
  ...
}: {
  _file = ./default.nix; # Error messages name this file, not the importer

  #--------------------------------------------------------------------#
  #-- Gaming Configuration
  #--------------------------------------------------------------------#

  #- Create shader cache directory (improves game startup performance)
  home = {
    file = {
      ".cache/mesa_shader_cache/.keep".text = "";
      #- Raise OpenAL's source limit; sound-heavy games (e.g. tModLoader +
      #- Calamity) pop without it
      ".alsoftrc".text = ''
        [general]
        sources = 512
      '';
    };

    #--- Wrappers
    packages = with pkgs; [
      #--- Vintage Story
      # (writeShellScriptBin "vintagestory-mesa" ''
      #   export MESA_GLTHREAD=true
      #   ${vintagestory}/bin/vintagestory "$@"
      # '')

      #--------------------------------------------------------------------#
      #-- Packages
      #--------------------------------------------------------------------#
      #--- Utility
      gamemode
      mangohud
      goverlay
      antimicrox

      #--- Wine
      wineWow64Packages.waylandFull
      dxvk
      vkd3d
      winetricks

      #--- Proton
      vkd3d-proton
      umu-launcher
      protontricks
      protonplus

      #--- Vulkan
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers

      #--- Other Dependencies
      lua5
      corefonts
      alsa-lib
      libGL

      #--- Performance Monitoring
      clinfo
      mesa-demos
      inxi
    ];

    #--------------------------------------------------------------------#
    #-- Environment Variables
    #--------------------------------------------------------------------#
    sessionVariables = {
      #--- Wine/Proton optimizations
      DXVK_HUD = "compiler"; # Show shader compilation (can disable by removing this)

      # Better shader caching
      MESA_SHADER_CACHE_DIR = "${config.home.homeDirectory}/.cache/mesa_shader_cache";

      # Increase cache size for large game library
      MESA_SHADER_CACHE_MAX_SIZE = "10G";
    };
  };

  #--------------------------------------------------------------------#
  #-- MangoHud Overlay
  #--------------------------------------------------------------------#
  #--- FPS-only overlay, top-right corner (stylix target disabled in theme/stylix.nix)
  #--- font_file: themed JetBrainsMono Nerd Font, Mono cut for fixed-width digits
  xdg.configFile."MangoHud/MangoHud.conf".text = ''
    fps_only
    position=top-right
    font_size=16
    background_alpha=0
    text_color=00FF00
    font_file=${config.stylix.fonts.monospace.package}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf
  '';

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./scripts/nix-gamescope.nix
      ./scripts/nix-performance.nix
      ./scripts/nix-vn.nix
      ./scripts/nix-rpgm.nix
    ]
    #--- Launchers (steam is in nixos/gaming; Hytale's is a Flatpak installed by hand)
    ++ lib.optionals user.gaming.steam [./steam-games.nix]
    ++ lib.optionals user.gaming.heroic [./launchers/heroic.nix]
    ++ lib.optionals user.gaming.prismlauncher [./launchers/prismlauncher.nix]
    ++ lib.optionals user.gaming.lutris [./launchers/lutris.nix]
    ++ lib.optionals user.gaming.faugus [./launchers/faugus.nix]
    ++ lib.optionals user.gaming.easyrpg [./launchers/easyrpg.nix]
    ++ lib.optionals user.gaming.twintail [./launchers/twintail.nix]
    #--- Games
    ++ lib.optionals user.gaming.feedback [./games/feedback.nix]
    ++ lib.optionals user.gaming.rocksmith [./games/rocksmith.nix]
    ++ lib.optionals user.gaming.tmodloader [./scripts/tml-prelaunch.nix]
    #--- Tools
    ++ lib.optionals user.gaming.r2modman [./tools/r2modman.nix]
    ++ lib.optionals user.gaming.satisfactoryModManager [./tools/satisfactory-mod-manager.nix]
    ++ lib.optionals user.gaming.pathOfBuilding [./tools/path-of-building.nix]
    ++ lib.optionals user.gaming.ludusavi [./tools/ludusavi.nix]
    ++ lib.optionals user.gaming.retroshelf [./tools/retroshelf.nix]
    ++ lib.optionals user.gaming.granblueRelinkMods [./tools/relink-mod-organizer.nix ./tools/reloaded-ii-gbfr.nix]
    ++ lib.optionals user.japanese.vn [./tools/japanese-vn.nix];
}
