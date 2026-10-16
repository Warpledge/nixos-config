#=====================================================================#
# NIRI SETTINGS (LAPTOP-SPECIFIC)
#=====================================================================#
{
  lib,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Display, Autostart & GPU Configuration
  #--------------------------------------------------------------------#
  home-manager.users.${username} = {
    #--- Disable auto-lock on laptop (server runs unattended)
    home.file.".config/DankMaterialShell/settings.json" = lib.mkForce {
      text = builtins.toJSON (
        (lib.importJSON ../../../modules/wm/niri/home/dms/settings.json)
        // {acLockTimeout = 0;}
      );
    };

    programs.niri.settings = {
      #--- Monitors
      # Defined in modules/wm/niri/home/core/monitors.nix
      #--- Autostart (Laptop-Specific)
      spawn-at-startup = [
        #--- Solaar - Logitech device manager
        #--- Runs in system tray and applies mouse settings automatically
        {command = ["solaar" "--window=hide"];}
      ];

      #--- GPU Configuration (Laptop-Specific)
      # Hybrid AMD/NVIDIA setup for Lenovo Legion 83EX
      environment = {
        # VA-API and GBM drivers for apps niri spawns; niri picks its own GPU with
        # debug.render-drm-device (WLR_DRM_DEVICES is wlroots-only)
        LIBVA_DRIVER_NAME = "radeonsi";
        GBM_BACKEND = "mesa";

        # Global NVIDIA offload, left off: route individual apps with nvidia-offload
        # __NV_PRIME_RENDER_OFFLOAD = "1";
        # __VK_LAYER_NV_optimus = "NVIDIA_only";
      };
    };
  };
}
