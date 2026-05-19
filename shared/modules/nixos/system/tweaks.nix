#=====================================================================#
# SYSTEM TWEAKS (KERNEL PARAMETERS, JOURNALD)
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Kernel Parameters
  #--------------------------------------------------------------------#
  boot.kernel.sysctl = {
    "vm.min_free_kbytes" = 1048576; # Keep 1GB free for emergency kernel use
    "vm.swappiness" = 10; # Prefer RAM over swap (10 = low swap usage)
    "vm.vfs_cache_pressure" = 50; # Reduce inode/dentry cache pressure
    "kernel.nmi_watchdog" = 0; # Disable NMI watchdog (reduces CPU overhead)
  };

  #--------------------------------------------------------------------#
  #-- Journald Logging Configuration
  #--------------------------------------------------------------------#
  services.journald.extraConfig = ''
    SystemMaxUse=500M # Maximum journal size on disk
    SystemKeepFree=1G # Always keep 1GB free space
    MaxRetentionSec=7day # Keep logs for 7 days
  '';
}
