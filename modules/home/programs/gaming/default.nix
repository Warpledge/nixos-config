#=====================================================================#
# GAMING ENVIRONMENT CONFIGURATION
#=====================================================================#
{
  pkgs,
  config,
  lib,
  hostConfig,
  ...
}: {
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
      satisfactorymodmanager

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

      #--- For tModLoader support
      dotnet-sdk_8
      mono

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
      ./scripts/tml-prelaunch.nix
    ]
    #--- Launchers (steam is in nixos/gaming; hytale is a hand-installed Flatpak)
    ++ lib.optionals hostConfig.gaming.heroic [./launchers/heroic.nix]
    ++ lib.optionals hostConfig.gaming.prismlauncher [./launchers/prismlauncher.nix]
    ++ lib.optionals hostConfig.gaming.lutris [./launchers/lutris.nix]
    ++ lib.optionals hostConfig.gaming.faugus [./launchers/faugus.nix]
    ++ lib.optionals hostConfig.gaming.easyrpg [./launchers/easyrpg.nix]
    ++ lib.optionals hostConfig.gaming.xsystem4 [./launchers/xsystem4]
    ++ lib.optionals hostConfig.gaming.twintail [./launchers/twintail.nix]
    #--- Games
    ++ lib.optionals hostConfig.gaming.feedback [./games/feedback.nix]
    ++ lib.optionals hostConfig.gaming.rocksmith [./games/rocksmith.nix]
    ++ lib.optionals hostConfig.gaming.easyrpg [./games/tobira-no-densetsu.nix]
    #--- Tools
    ++ lib.optionals hostConfig.gaming.r2modman [./tools/r2modman.nix]
    ++ lib.optionals hostConfig.gaming.pathOfBuilding [./tools/path-of-building.nix]
    ++ lib.optionals hostConfig.gaming.ludusavi [./tools/ludusavi.nix]
    ++ lib.optionals hostConfig.gaming.granblueRelinkMods [./tools/relink-mod-organizer.nix ./tools/reloaded-ii-gbfr.nix]
    ++ lib.optionals hostConfig.japanese.vn [./tools/japanese-vn.nix];
}
