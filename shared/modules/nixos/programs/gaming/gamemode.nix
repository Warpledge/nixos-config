#=====================================================================#
# GAMEMODE CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    gamemode # GameMode daemon for automatic optimizations
    libnotify # Desktop notifications for GameMode start/stop
  ];

  #--------------------------------------------------------------------#
  #-- GameMode Settings
  #--------------------------------------------------------------------#
  programs.gamemode = {
    enable = true; # Enable GameMode service
    enableRenice = true; # Allow nice priority changes (CAP_SYS_NICE)
    settings = {
      general = {
        renice = 15; # Boost game process priority (+15)
        desiredgov = "performance"; # Use performance CPU governor
        inhibit_screensaver = 1; # Disable screensaver during gaming
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility"; # Apply GPU tweaks
        gpu_device = 0; # GPU device to optimize
        amd_performance_level = "high"; # AMD GPU higher clock level
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations activated'"; # Notify on start
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations deactivated'"; # Notify on stop
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- Kernel Sysctls for Gaming
  #--------------------------------------------------------------------#
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Max memory map areas (for complex games)
    "fs.inotify.max_user_watches" = 524288; # Inotify watches limit (game launchers)
    "vm.stat_interval" = 10; # Update VM stats less frequently
    "vm.page-cluster" = 0; # Disable swap readahead
    "vm.zone_reclaim_mode" = 0; # Don't reclaim memory from zones
  };
}
