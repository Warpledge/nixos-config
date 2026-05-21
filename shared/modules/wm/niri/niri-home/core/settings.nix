#=====================================================================#
# NIRI SETTINGS
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    seatd
    jaq
  ];

  #--------------------------------------------------------------------#
  #-- Niri Configuration
  #--------------------------------------------------------------------#
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      #--- Environment Variables
      environment = {
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        SDL_VIDEODRIVER = "wayland";
        QML_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml";
      };

      #--- Startup Applications
      spawn-at-startup = [
        {command = ["bash" "-c" "wl-paste --watch cliphist store &"];} # Clipboard History
        {command = ["xrdb" "-merge" "/home/warpledge/.Xresources"];} # Xwayland cursor theme
      ];

      #--- Input Configuration
      input = {
        keyboard = {
          xkb.layout = "us";
          numlock = true;
        };
        touchpad = {
          click-method = "button-areas";
          dwt = true; # disable-while-typing
          dwtp = true; # disable-while-trackpointing
          natural-scroll = true;
          scroll-method = "two-finger";
          tap = true;
          tap-button-map = "left-right-middle";
          middle-emulation = true; # emulate middle mouse button by pressing left and right buttons simultaneously
          accel-profile = "adaptive";
        };
        mouse = {
          accel-profile = "flat";
        };
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "90%";
        };
        warp-mouse-to-focus.enable = false; # automatically move cursor to focused window
        workspace-auto-back-and-forth = true; # automatic workspace switching behavior
      };

      #--- Screenshot Configuration
      screenshot-path = "~/Pictures/Screenshots/Screenshot-from-%Y-%m-%d-%H-%M-%S.png";

      #--- Monitor Configuration (Host-Specific)
      # Monitor configuration moved to hosts/{desktop,laptop}/niri/default.nix
      # to allow per-device customization

      #--- UI & Appearance
      overview = {
        workspace-shadow.enable = false;
        backdrop-color = "transparent"; # "transparent" "#${base01}" etc
      };
      gestures = {hot-corners.enable = true;};
      cursor = {
        size = 24;
        theme = "Bibata-Modern-Ice";
      };

      #--- Layout Configuration
      layout = {
        focus-ring = {
          enable = true; # displays around windows
          width = 2;
          active.color = "#45475a"; # Surface 1
          inactive.color = "#181825"; # Mantle
          urgent.color = "#f38ba8"; # Red
        };
        border = {
          enable = false; # displays inside windows
          width = 2;
          active.color = "#585b70"; # Surface 2
          inactive.color = "#181825"; # Mantle
        };
        shadow = {
          enable = false;
        };
        preset-column-widths = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
          {proportion = 1.0;}
        ];
        default-column-width = {proportion = 0.5;};

        preset-window-heights = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
          {proportion = 1.0;}
        ];

        gaps = 6;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };

        tab-indicator = {
          hide-when-single-tab = true;
          place-within-column = true;
          position = "left";
          corner-radius = 20.0;
          gap = -12.0;
          gaps-between-tabs = 10.0;
          width = 4.0;
          length.total-proportion = 0.1;
        };
      };

      #--- Animation Configuration
      animations.window-resize.custom-shader = ''
        vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
          vec3 coords_next_geo = niri_curr_geo_to_next_geo * coords_curr_geo;

          vec3 coords_stretch = niri_geo_to_tex_next * coords_curr_geo;
          vec3 coords_crop = niri_geo_to_tex_next * coords_next_geo;

          // We can crop if the current window size is smaller than the next window
          // size. One way to tell is by comparing to 1.0 the X and Y scaling
          // coefficients in the current-to-next transformation matrix.
          bool can_crop_by_x = niri_curr_geo_to_next_geo[0][0] <= 1.0;
          bool can_crop_by_y = niri_curr_geo_to_next_geo[1][1] <= 1.0;

          vec3 coords = coords_stretch;
          if (can_crop_by_x)
              coords.x = coords_crop.x;
          if (can_crop_by_y)
              coords.y = coords_crop.y;

          vec4 color = texture2D(niri_tex_next, coords.st);

          // However, when we crop, we also want to crop out anything outside the
          // current geometry. This is because the area of the shader is unspecified
          // and usually bigger than the current geometry, so if we don't fill pixels
          // outside with transparency, the texture will leak out.
          //
          // When stretching, this is not an issue because the area outside will
          // correspond to client-side decoration shadows, which are already supposed
          // to be outside.
          if (can_crop_by_x && (coords_curr_geo.x < 0.0 || 1.0 < coords_curr_geo.x))
              color = vec4(0.0);
          if (can_crop_by_y && (coords_curr_geo.y < 0.0 || 1.0 < coords_curr_geo.y))
              color = vec4(0.0);

          return color;
        }
      '';

      #--------------------------------------------------------------------#
      #-- MISC --#
      #--------------------------------------------------------------------#
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;
    };
  };
}
