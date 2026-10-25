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

          #--- Touchscreen: three-finger drag steps through windows like Mod+MMB
          # P fires on each -T pixels moved while fingers stay down. Kept under a
          # shell: lisgd spawned directly by niri exits at once.
          {
            command = [
              "${pkgs.writeShellScript "touch-gestures" ''
                ${pkgs.lisgd}/bin/lisgd \
                  -d /dev/input/by-path/platform-AMDI0010:00-event -T 150 \
                  -g '3,RL,*,*,P,niri msg action focus-column-right' \
                  -g '3,LR,*,*,P,niri msg action focus-column-left'
              ''}"
            ];
          }
        ];
      };
    })
    machine.users;
}
