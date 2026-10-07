#=====================================================================#
# HYPRLAND SETTINGS (LAPTOP-SPECIFIC)
#=====================================================================#
{
  lib,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Display, Input & GPU Configuration
  #--------------------------------------------------------------------#
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      #--- Input Devices
      config.cursor = {
        no_hardware_cursors = true; # Disable hardware cursors on laptop
      };

      #--- Autostart (Laptop-Specific)
      on = [
        {
          _args = [
            "hyprland.start"
            #--- Solaar - Logitech device manager
            #--- Runs in system tray and applies mouse settings automatically
            (lib.generators.mkLuaInline ''function() hl.exec_cmd("solaar --window=hide") end'')
          ];
        }
      ];

      #--- GPU Configuration (Laptop-Specific)
      #--- Hybrid AMD/NVIDIA setup for Lenovo Legion 83EX
      env = map (kv: {_args = lib.splitString "," kv;}) [
        # GPU Configuration - Use AMD iGPU for Hyprland on laptop
        "LIBVA_DRIVER_NAME,radeonsi"
        "GBM_BACKEND,mesa"
        "WLR_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0"

        # NVIDIA offload available via nvidia-offload command
        "__NV_PRIME_RENDER_OFFLOAD,1"
        "__VK_LAYER_NV_optimus,NVIDIA_only"
      ];
    };
  };
}
