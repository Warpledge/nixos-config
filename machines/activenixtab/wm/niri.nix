#=====================================================================#
# NIRI SETTINGS (FLOW Z13)
#=====================================================================#
#- For every user on this machine
{
  lib,
  pkgs,
  machine,
  ...
}: {
  home-manager.users =
    lib.mapAttrs (_: _: {
      dms.extraSettings.powerMenuActions = ["reboot" "logout" "poweroff" "lock" "restart"];

      programs.niri.settings = {
        #--- Monitors - internal panel (2560x1600@180Hz, 13.4")
        # No refresh given: niri picks the highest the panel offers
        outputs."eDP-1" = {
          mode = {
            width = 2560;
            height = 1600;
          };
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.5;
        };

        #--- Touchpad scroll speed matched to GTK apps
        # Per finger movement, GTK scrolls 2.5x, Qt widgets 6x and Chromium/Electron
        # about 10x (measured 2026-10-25); Qt felt fine as is. Also scales the mouse
        # wheel in these apps.
        window-rules = [
          {
            matches = [
              {app-id = "^(vivaldi-stable|chromium(-browser)?|electron)$";}
              {app-id = "^(vesktop|discord|codium|obsidian)$";}
              {app-id = "^(com\\.anthropic\\.Claude|ai\\.elementlabs\\.lmstudio)$";}
            ];
            scroll-factor = 0.25;
          }
          #--- Ark: open-focused so it doesn't float unexpectedly
          {
            matches = [{app-id = "^org\\.kde\\.ark$";}];
            open-focused = true;
          }
          #--- Steam Friends List: keep tiled, not floating
          {
            matches = [
              {app-id = "^steam$";}
              {title = "^Friends List$";}
            ];
            open-floating = false;
          }
        ];

        #--- Auto-rotation from the accelerometer (hardware.sensor.iio)
        spawn-at-startup = [
          # iio-niri 2.x prints its help and exits without a subcommand
          {command = ["${pkgs.iio-niri}/bin/iio-niri" "listen" "--monitor" "eDP-1"];}

          #--- Touchscreen: three-finger drags scroll columns and workspaces
          # touch-gestures.py turns them into touchpad swipes niri follows
          {
            command = [
              "${pkgs.writeShellScript "touch-gestures" ''
                ${pkgs.python3.withPackages (p: [p.evdev])}/bin/python3 \
                  ${./touch-gestures.py} /dev/input/by-path/platform-AMDI0010:00-event \
                  osk-toggle
              ''}"
            ];
          }
        ];
      };
    })
    machine.users;
}
