#=====================================================================#
# GAMING ENVIRONMENT CONFIGURATION
#=====================================================================#
{
  pkgs,
  config,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Gaming Configuration
  #--------------------------------------------------------------------#

  #- Create shader cache directory (improves game startup performance)
  home = {
    file = {
    ".cache/mesa_shader_cache/.keep".text = "";
    ".cache/radv_builtin_shaders64/.keep".text = "";
    #- Raise OpenAL source limit to prevent audio popping in sound-heavy games (e.g. tModLoader + Calamity)
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
    r2modman
    satisfactorymodmanager
    rusty-path-of-building

    #--- Launchers
    heroic
    prismlauncher

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
    game-devices-udev-rules
    corefonts
    alsa-lib
    libGL
    mdf2iso # Convert .mdf/.mds disc images to .iso for mounting

    #--- Performance Monitoring
    clinfo
    mesa-demos
    inxi
    ];

    #--------------------------------------------------------------------#
    #-- Environment Variables
    #--------------------------------------------------------------------#
    sessionVariables = {
    #--- Mesa/AMD Graphics Optimizations
    MESA_GLTHREAD = "true"; # AMD specific OpenGL application performance boost
    mesa_glthread = "true"; # Lowercase variant for compatibility

    #--- Wine/Proton optimizations
    DXVK_HUD = "compiler"; # Show shader compilation (can disable by removing this)
    DXVK_ASYNC = "1"; # Enable async shader compilation to reduce stutters
    DXVK_STATE_CACHE_PATH = "$HOME/.cache/dxvk"; # Centralized DXVK cache
    STAGING_SHARED_MEMORY = "1"; # Wine staging shared memory
    WINE_LARGE_ADDRESS_AWARE = "1"; # Enable 4GB+ memory for 32-bit games

    #--- Additional performance variables
    __GL_THREADED_OPTIMIZATIONS = "1"; # NVIDIA variable that doesn't hurt on AMD
    __GL_YIELD = "USLEEP"; # Better CPU usage in some scenarios

    #--- ADDITIONAL Proton optimizations
    PROTON_ENABLE_NVAPI = "1"; # Better GPU info reporting
    PROTON_NO_ESYNC = "0"; # Ensure esync is enabled
    PROTON_NO_FSYNC = "0"; # Ensure fsync is enabled
    PROTON_FORCE_LARGE_ADDRESS_AWARE = "1"; # Better memory usage

    #--- GE-Proton specific
    PROTON_LOG = "0"; # Disable logging for performance
    PROTON_DUMP_DEBUG_COMMANDS = "0"; # No debug overhead

    #--- Better frame pacing
    vblank_mode = "0"; # Let game control vsync
    __GL_SYNC_TO_VBLANK = "0"; # Nvidia equivalent

    # Better shader caching
    MESA_SHADER_CACHE_DIR = "${config.home.homeDirectory}/.cache/mesa_shader_cache";
    RADV_BUILTIN_CACHE_PATH = "${config.home.homeDirectory}/.cache/radv_builtin_shaders64";
    AMD_SHADER_DISK_CACHE_PATH = "${config.home.homeDirectory}/.cache/amd_shader_cache";

    # Increase cache size for large game library
    MESA_SHADER_CACHE_MAX_SIZE = "10G";
    };
  };
}
