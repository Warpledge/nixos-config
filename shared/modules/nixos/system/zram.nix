#=====================================================================#
# ZRAM CONFIGURATION (COMPRESSED MEMORY SWAP)
#=====================================================================#
{
  #--- ZRAM Compressed Swap
  zramSwap = {
    enable = true; # Enable compressed in-RAM swap
    algorithm = "zstd"; # Zstandard compression (fast, high ratio)
    priority = 5; # Use ZRAM before disk swap
    memoryPercent = 50; # Use 50% of available RAM for ZRAM
  };
}
