#=====================================================================#
# HYPRLAND CORE CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    #--- Main Dependencies
    wlr-randr
    gnome-themes-extra
    hyprpicker # colorpicker
    wl-clip-persist # copy paste functionality
    glib
    libva
    wayland-utils
    wayland-protocols
    wayland
    direnv
    meson
    hyprlock
  ];

  #--------------------------------------------------------------------#
  #-- Hyprland Configuration
  #--------------------------------------------------------------------#
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua"; # Lua shapes: hl.config, hl.bind, hl.window_rule, ...
    # Required before the settings, so general.layout = "quad" resolves
    extraLuaFiles."layouts.quad" = ./quad.lua;
    xwayland.enable = true;
    systemd = {
      enable = true;
      # https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#programs-dont-work-in-systemd-services-but-do-on-the-terminal
      variables = ["--all"];
    };
  };

  #--------------------------------------------------------------------#
  #-- Systemd Integration
  #--------------------------------------------------------------------#
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    ./animations.nix
    ./binds.nix
    ./rules/windowrules
    ./rules/layerrules
    ./settings.nix
    ./variables.nix
  ];
}
