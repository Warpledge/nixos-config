#=====================================================================#
# NIRI SETTINGS (THIS MACHINE)
#=====================================================================#
#- Loaded when settings.nix picks windowManager = "niri", for every user on
#- this machine. With no `outputs` entry niri gives each monitor its
#- preferred mode; `niri msg outputs` lists the monitors and their modes.
{
  lib,
  machine,
  ...
}: {
  home-manager.users =
    lib.mapAttrs (_: _: {
      programs.niri.settings = {
        #--- Monitors, by connector name, for example:
        # outputs."DP-1" = {
        #   mode = {
        #     width = 2560;
        #     height = 1440;
        #     refresh = 143.973;
        #   };
        #   position = {
        #     x = 0;
        #     y = 0;
        #   };
        #   scale = 1.0;
        # };
      };
    })
    machine.users;
}
