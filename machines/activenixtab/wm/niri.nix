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
          {command = ["${pkgs.iio-niri}/bin/iio-niri"];}
        ];
      };
    })
    machine.users;
}
