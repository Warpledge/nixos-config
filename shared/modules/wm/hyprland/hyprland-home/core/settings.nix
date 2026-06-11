#=====================================================================#
# HYPRLAND SETTINGS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Shell Aliases
  #--------------------------------------------------------------------#
  #--- Hyprctl Aliases
  programs.zsh = {
    shellAliases = {
      hr = "hyprctl reload";
      hc = "hyprctl clients";
      hl = "hyprctl layers";
      hm = "hyprctl monitors";
    };
  };

  #--------------------------------------------------------------------#
  #-- Hyprland Configuration
  #--------------------------------------------------------------------#
  # Prevent HM backup collision when switching WMs back to hyprland
  xdg.configFile."hypr/hyprland.conf".force = true;

  wayland.windowManager.hyprland = {
    settings = {
      #--- Autostart
      exec-once =
        [
          #--- Authentication agents
          "gnome-keyring-daemon --start --components=secrets"

          #--- System tray and services
          "nm-applet"
        ]
        #--- Japanese input method daemon (controlled by hostConfig)
        ++ lib.optional hostConfig.japanese.ime "fcitx5 -d -r";

      cursor = {
        no_warps = true;
        zoom_factor = 1;
        zoom_rigid = false;
        hotspot_padding = 1;
        inactive_timeout = 3; # Hide cursor after 3 seconds of inactivity (OLED burn-in prevention)
      };
      master = {
        new_status = "master";
        allow_small_split = true;
        mfact = 0.5;
      };
      general = {
        layout = "master";
        resize_on_border = false;

        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;

        "col.inactive_border" = lib.mkForce "rgb(1e1e2e)"; # Fully transparent
        "col.active_border" = lib.mkForce "rgb(cba6f7)"; # Mauve

        snap = {
          enabled = true;
          window_gap = 4;
          monitor_gap = 5;
          respect_gaps = true;
        };
      };
      decoration = {
        # active_opacity = 0.90;
        # inactive_opacity = 0.90;
        fullscreen_opacity = 1;
        rounding = 18;

        blur = {
          enabled = true;
          size = 8;
          passes = 4;
          brightness = 0.95;
          contrast = 1.2; # Reduced from 1.25 for OLED color accuracy
          ignore_opacity = true;
          noise = 0;
          new_optimizations = true;
          xray = true;
          special = true;
          popups = true;
          popups_ignorealpha = 0.85;
          input_methods = true;
          input_methods_ignorealpha = 0.85;
        };

        shadow = {
          enabled = false;
          offset = "0 2";
          range = 30;
          render_power = 4;
          color = lib.mkForce "rgba(00000020)";
        };
        #--- Dim
        dim_inactive = true;
        dim_strength = 0.025;
        dim_special = 0.07;
      };
      gestures = {
        workspace_swipe_distance = 700;
        workspace_swipe_cancel_ratio = 0.2;
        workspace_swipe_min_speed_to_force = 5;
        workspace_swipe_direction_lock = true;
        workspace_swipe_direction_lock_threshold = 10;
        workspace_swipe_create_new = true;
      };
      dwindle = {
        preserve_split = true;
        smart_split = false;
        smart_resizing = false;
        # precise_mouse_move = true;
      };
      misc = {
        vrr = 0;
        disable_autoreload = false;
        disable_hyprland_logo = true;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = false;
        enable_swallow = false;
        disable_splash_rendering = true;
        focus_on_activate = false;
        on_focus_under_fullscreen = 2;
        middle_click_paste = false;
      };
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        force_no_accel = 1;
        numlock_by_default = true;

        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          clickfinger_behavior = true;
          scroll_factor = 1.0;
        };
      };
      binds = {
        scroll_event_delay = 0;
        hide_special_on_workspace_change = true;
      };
    };
  };
}
