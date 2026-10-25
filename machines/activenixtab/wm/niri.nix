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
                  ${./touch-gestures.py} /dev/input/by-path/platform-AMDI0010:00-event
              ''}"
            ];
          }
        ];
      };
    })
    machine.users;
}
