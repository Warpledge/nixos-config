#=====================================================================#
# SWAPFILE CONFIGURATION (LAPTOP OOM SAFETY NET)
#=====================================================================#
#--- 8GB swapfile as a last-resort fallback when ZRAM fills up.
#--- Priority 0 ensures ZRAM (priority 5) is always exhausted first.
#--- Not expected to be used during normal operation.
{
  #--------------------------------------------------------------------#
  #-- Swapfile
  #--------------------------------------------------------------------#
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8192; # 8GB (MiB)
      priority = 0; # Below ZRAM (5); the kernel only takes -1 to 32767
    }
  ];
}
