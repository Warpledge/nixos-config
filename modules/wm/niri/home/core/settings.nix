#=====================================================================#
# NIRI SETTINGS
#=====================================================================#
{
  config,
  osConfig,
  pkgs,
  lib,
  machine,
  user,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
in {
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
    package = osConfig.programs.niri.package; # set in niri/session.nix
    settings = {
      #--- Environment Variables
      environment = {
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        SDL_VIDEODRIVER = "wayland,x11";
        QML_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml";
      };

      #--- Startup Applications
      # Japanese input method daemon (controlled by user settings)
      spawn-at-startup = lib.optional user.japanese.ime {command = ["fcitx5" "-d" "-r"];};

      #--- Input Configuration
      # Pointer speed and acceleration, scrolling, tapping, disable-while-typing,
      # middle-click emulation and Num Lock are DMS's (seeded in dms/default.nix),
      # so its Mouse & Touchpad and Keyboard pages can turn them off too
      input = {
        keyboard = {
          xkb.layout = machine.keyboardLayout;
        };
        touchpad = {
          click-method = "button-areas";
          dwtp = true; # disable-while-trackpointing
          tap-button-map = "left-right-middle";
          # niri-flake turns these on by default; off here leaves them out of
          # hm.kdl, so DMS's input.kdl decides
          tap = false;
          natural-scroll = false;
        };
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%"; # hovering a part-hidden window won't scroll to it
        };
        warp-mouse-to-focus.enable = false; # automatically move cursor to focused window
        # re-pressing the active workspace's key returns to the previous one
        workspace-auto-back-and-forth = true;
      };

      #--- Screenshot Configuration
      screenshot-path = "~/Pictures/Screenshots/Screenshot-from-%Y-%m-%d-%H-%M-%S.png";

      #--- Monitor Configuration (Machine-Specific)
      # Per machine, in machines/<name>/wm/niri.nix

      #--- UI & Appearance
      overview = {
        workspace-shadow.enable = false;
        backdrop-color = "transparent"; # "transparent" "#${base01}" etc
      };
      gestures = {hot-corners.enable = true;};
      cursor = {
        inherit (config.stylix.cursor) size;
        theme = config.stylix.cursor.name;
        hide-when-typing = true;
      };

      #--- Recent Windows Switcher (Alt+Tab)
      # Matches the window corner radius in rules.nix
      recent-windows.highlight.corner-radius = 12;

      #--- Layout Configuration
      layout = {
        # Shows the backdrop wallpaper (rules.nix) through workspaces
        background-color =
          lib.mkIf (user.wallpaper == "engine") "transparent";
        focus-ring = {
          enable = true; # displays around windows
          width = 2;
          active.color = colors.base04; # Surface 2
          inactive.color = colors.base01; # Mantle
          urgent.color = colors.base08; # Red
        };
        border = {
          enable = false; # displays inside windows
          width = 2;
          active.color = colors.base04; # Surface 2
          inactive.color = colors.base01; # Mantle
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
        always-center-single-column = true;

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
      animations = {
        window-resize.custom-shader = ''
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

        #--- Expanding circle, from niri's docs/wiki/examples/open_custom_shader.frag
        window-open = {
          kind.easing = {
            duration-ms = 250;
            curve = "ease-out-expo";
          };
          custom-shader = ''
            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);

              vec2 coords = (coords_geo.xy - vec2(0.5, 0.5)) * size_geo.xy * 2.0;
              coords = coords / length(size_geo.xy);
              float p = niri_clamped_progress;
              if (p * p <= dot(coords, coords))
                  color = vec4(0.0);

              return color;
            }
          '';
        };

        #--- Fall and rotate, from niri's docs/wiki/examples/close_custom_shader.frag
        # The example asks for a linear curve
        window-close = {
          kind.easing = {
            duration-ms = 150;
            curve = "linear";
          };
          custom-shader = ''
            vec4 close_color(vec3 coords_geo, vec3 size_geo) {
              // Simulate an accelerated fall: square the (linear) progress.
              float progress = niri_clamped_progress * niri_clamped_progress;

              // Rotation pivot at the bottom center of the window.
              vec2 coords = (coords_geo.xy - vec2(0.5, 1.0)) * size_geo.xy;

              // Move the window down to simulate a fall.
              coords.y -= progress * 200.0;

              // Randomize rotation direction and maximum angle.
              float random = (niri_random_seed - 0.5) / 2.0;
              random = sign(random) - random;
              float max_angle = 0.05 * random;

              // Rotate the window around the pivot point.
              float angle = progress * max_angle;
              mat2 rotate = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
              coords = rotate * coords;

              // Transform the coordinates back.
              coords_geo = vec3(coords / size_geo.xy + vec2(0.5, 1.0), 1.0);

              // Sample the window texture and fade it out.
              vec3 coords_tex = niri_geo_to_tex * coords_geo;
              vec4 color = texture2D(niri_tex, coords_tex.st);
              return color * (1.0 - niri_clamped_progress);
            }
          '';
        };
      };

      #--------------------------------------------------------------------#
      #-- MISC --#
      #--------------------------------------------------------------------#
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;
    };
  };
}
