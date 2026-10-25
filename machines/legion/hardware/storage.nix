#=====================================================================#
# STORAGE DRIVE (LUKS, UNLOCKED AFTER BOOT WITH A KEY FILE)
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Stage-2 Unlock
  #--------------------------------------------------------------------#
  # The key file lives on the encrypted root, outside the repo
  environment.etc.crypttab.text = ''
    storage /dev/disk/by-partlabel/storage /root/cryptsetup-keys.d/storage.key luks,discard,nofail
  '';

  #--------------------------------------------------------------------#
  #-- Mounts
  #--------------------------------------------------------------------#
  fileSystems."/mnt/storage" = {
    device = "/dev/mapper/storage";
    fsType = "ext4";
    options = ["nofail" "x-gvfs-show"]; # x-gvfs-show: list in Nautilus's sidebar
  };
}
