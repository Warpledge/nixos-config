#=====================================================================#
# HOME SESSION VARIABLES
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Session Variables
  #--------------------------------------------------------------------#
  # Variables that affect user applications and session behavior

  home.sessionVariables = {
    #--- Session type
    XDG_SESSION_TYPE = "wayland";

    #--- Qt configuration
    QT_AUTO_SCREEN_SCALE_FACTOR = "1"; # Disable Qt auto-scaling
    QT_QPA_PLATFORM = "wayland"; # Use Wayland, fallback to X11
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1"; # Disable Qt window decorations

    #--- Wayland application support
    MOZ_ENABLE_WAYLAND = "1"; # Enable Wayland in Firefox
    ANKI_WAYLAND = "1"; # Enable Wayland in Anki
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Ozone-based apps (Chrome, VSCode, etc.)
    ELECTRON_OZONE_PLATFORM_HINT = "wayland"; # Force Wayland for Electron apps

    #--- Graphics and rendering
    SDL_VIDEODRIVER = "wayland"; # Use Wayland for SDL applications
    CLUTTER_BACKEND = "wayland"; # Use Wayland for Clutter toolkit
    GDK_BACKEND = "wayland"; # GTK apps prefer Wayland

    #--- WLR backend (for Niri and other wlroots compositors)
    WLR_BACKEND = "vulkan"; # Use Vulkan backend
    WLR_RENDERER = "vulkan"; # Use Vulkan renderer

    #--- Development and tools
    DIRENV_LOG_FORMAT = ""; # Disable direnv logging format
    EDITOR = "zed --wait"; # Default editor (for git, /memory, etc.)
    VISUAL = "zed --wait"; # Visual editor

    #--- Gaming
    GAMESCOPE_DISABLE_VULKAN_RENDERDOC_CAPTURE = "1"; # Disable RenderDoc capture in Gamescope

    #--- Proton
    PROTON_USE_NTSYNC = "1";
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_XESS_UPGRADE = "1";
    PROTON_FSR4_UPGRADE = "1";
  };
}
