#=====================================================================#
# COSMIC COMPOSITOR SETTINGS
#=====================================================================#
_: {
  #--------------------------------------------------------------------#
  #-- Declarative Configuration
  #--------------------------------------------------------------------#
  # Master switch for cosmic-manager; gates every other
  # wayland.desktopManager.cosmic.* option in this directory.
  wayland.desktopManager.cosmic = {
    enable = true;

    #--------------------------------------------------------------------#
    #-- Compositor
    #--------------------------------------------------------------------#
    compositor = {
      #--- Tiling
      autotile = true;
      autotile_behavior = {
        __type = "enum";
        variant = "PerWorkspace";
      };

      #--- Focus
      active_hint = true;
      cursor_follows_focus = false;
      focus_follows_cursor = true;
      focus_follows_cursor_delay = 100;

      #--- Mouse: Flat = no pointer acceleration, speed 0.0 = neutral
      # Mice only; the laptop touchpad uses input_touchpad and is left alone.
      input_default = {
        acceleration = {
          __type = "optional";
          value = {
            profile = {
              __type = "optional";
              value = {
                __type = "enum";
                variant = "Flat";
              };
            };
            speed = 0.0;
          };
        };
      };

      #--- Keep X11 clients at native scale
      descale_xwayland = false;
    };
  };

  #--------------------------------------------------------------------#
  #-- Desktop Icons
  #--------------------------------------------------------------------#
  wayland.desktopManager.cosmic.configFile."com.system76.CosmicFiles" = {
    version = 1;
    entries.desktop.show_content = false;
  };
}
