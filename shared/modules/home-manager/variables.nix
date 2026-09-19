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
    QT_AUTO_SCREEN_SCALE_FACTOR = "1"; # Qt scales UIs from the monitor's reported DPI
    QT_QPA_PLATFORM = "wayland;xcb"; # Fallback matters: a Qt app with no wayland plugin aborts without it
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    #--- Wayland application support
    MOZ_ENABLE_WAYLAND = "1"; # Enable Wayland in Firefox
    ANKI_WAYLAND = "1";
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Ozone-based apps (Chrome, VSCode, etc.)
    ELECTRON_OZONE_PLATFORM_HINT = "wayland"; # Force Wayland for Electron apps

    #--- Graphics and rendering
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland"; # Use Wayland for Clutter toolkit
    GDK_BACKEND = "wayland,x11"; # X11-only GTK/JUCE apps cannot start without the fallback

    #--- WLR backend (for Niri and other wlroots compositors)
    WLR_BACKEND = "vulkan";
    WLR_RENDERER = "vulkan";

    #--- Development and tools
    DIRENV_LOG_FORMAT = ""; # Disable direnv logging format
    EDITOR = "zeditor --wait"; # Default editor (for git, /memory, etc.); binary is zeditor, not zed
    VISUAL = "zeditor --wait";

    #--- Gaming
    GAMESCOPE_DISABLE_VULKAN_RENDERDOC_CAPTURE = "1";

    #--- Proton
    PROTON_USE_NTSYNC = "1";
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_XESS_UPGRADE = "1";
    PROTON_FSR4_UPGRADE = "1";
  };
}
