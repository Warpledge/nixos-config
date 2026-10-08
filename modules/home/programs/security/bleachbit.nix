#=====================================================================#
# BLEACHBIT
#=====================================================================#
#- Disk cleaner for caches, logs and browser leftovers. Cleaner sets are
#- chosen in the app; nothing runs on a schedule.
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [pkgs.bleachbit];
}
