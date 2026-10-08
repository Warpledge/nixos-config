#=====================================================================#
# ANDROID DEBUG BRIDGE (ADB) SERVICE
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Android Tools & Utilities
  #--------------------------------------------------------------------#
  #--- Provides adb, fastboot, and Android debloater
  #--- systemd 258+ handles uaccess rules automatically
  environment.systemPackages = with pkgs; [
    android-tools
    universal-android-debloater
  ];
}
