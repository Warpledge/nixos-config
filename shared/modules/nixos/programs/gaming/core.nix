#=====================================================================#
# GAMING CORE CONFIGURATION
#=====================================================================#
{
  imports = [
    ./esync.nix
    ./gamemode.nix
    ./java.nix
    ./steam.nix
  ];

  #--------------------------------------------------------------------#
  #-- Kernel Sysctls
  #--------------------------------------------------------------------#
  boot.kernel.sysctl = {
    "vm.unprivileged_userfaultfd" = 1; # Enable userfaultfd for Wine/emulators
  };

  #--------------------------------------------------------------------#
  #-- Kernel Parameters
  #--------------------------------------------------------------------#
  boot.kernelParams = [
    "preempt=full" # Full preemption for better responsiveness
    "threadirqs" # Run IRQ handlers in threads (lower latency)
    "nowatchdog" # Disable watchdog (lower overhead)
  ];

  #--------------------------------------------------------------------#
  #-- Gamescope Compositor
  #--------------------------------------------------------------------#
  programs.gamescope = {
    enable = true; # Gamescope Wayland compositor for Steam games
    capSysNice = false; # Don't require CAP_SYS_NICE
    args = [
      "--rt" # Realtime scheduling support
      "--expose-wayland" # Expose Wayland socket for native games
      "--force-grab-cursor" # Force cursor grabbing
    ];
  };
}
