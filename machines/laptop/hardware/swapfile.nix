#=====================================================================#
# SWAPFILE CONFIGURATION (LAPTOP OOM SAFETY NET)
#=====================================================================#
#--- 8GB swapfile as a last-resort fallback when ZRAM fills up.
#--- Priority -10 ensures ZRAM (priority 5) is always exhausted first.
#--- Not expected to be used during normal operation.
{
  #--------------------------------------------------------------------#
  #-- Swapfile
  #--------------------------------------------------------------------#
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8192; # 8GB (MiB)
      priority = -10; # Lower than ZRAM (priority 5) — only used when ZRAM fills
    }
  ];
}
