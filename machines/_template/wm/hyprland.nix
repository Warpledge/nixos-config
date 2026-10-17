#=====================================================================#
# HYPRLAND SETTINGS (THIS MACHINE)
#=====================================================================#
#- Loaded when settings.nix picks windowManager = "hyprland", for every user
#- on this machine. With no monitor entry Hyprland gives each monitor its
#- preferred mode; `hyprctl monitors` lists them.
{
  lib,
  machine,
  ...
}: {
  home-manager.users =
    lib.mapAttrs (_: _: {
      wayland.windowManager.hyprland.settings = {
        #--- Monitors, for example:
        # monitor = [
        #   {
        #     output = "DP-1";
        #     mode = "2560x1440@144";
        #     position = "0x0";
        #     scale = 1.0;
        #   }
        # ];
      };
    })
    machine.users;
}
