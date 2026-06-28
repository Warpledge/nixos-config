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
        (lib.importJSON ../../../shared/modules/wm/niri/niri-home/shell/dms/settings.json)
        // {acLockTimeout = 0;}
      );
    };

    programs.niri.settings = {
      #--- Monitors
      # Defined in shared/modules/wm/niri/niri-home/core/monitors.nix
      #--- Autostart (Laptop-Specific)
      spawn-at-startup = [
        #--- Solaar - Logitech device manager
        #--- Runs in system tray and applies mouse settings automatically
        {command = ["solaar" "--window=hide"];}
      ];

      #--- GPU Configuration (Laptop-Specific)
      # Hybrid AMD/NVIDIA setup for Lenovo Legion 83EX
      environment = {
        # GPU Configuration - Use AMD iGPU for Niri on laptop
        LIBVA_DRIVER_NAME = "radeonsi";
        GBM_BACKEND = "mesa";
        # AMD iGPU is card1, NVIDIA is card0 on laptop
        WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";

        # NVIDIA offload available via nvidia-offload command
        # Commented out - these may interfere with Noctalia Shell on AMD
        # __NV_PRIME_RENDER_OFFLOAD = "1";
        # __VK_LAYER_NV_optimus = "NVIDIA_only";
      };
    };
  };
}
