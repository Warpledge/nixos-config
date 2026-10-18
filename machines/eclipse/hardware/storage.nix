#=====================================================================#
# GAME STORAGE DRIVES (LUKS, UNLOCKED AFTER BOOT WITH KEY FILES)
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Stage-2 Unlock
  #--------------------------------------------------------------------#
  # Key files live on the encrypted root, outside the repo
  environment.etc.crypttab.text = ''
    games /dev/disk/by-partlabel/games /root/cryptsetup-keys.d/games.key luks,discard,nofail
    games2 /dev/disk/by-partlabel/games2 /root/cryptsetup-keys.d/games2.key luks,discard,nofail
  '';

  #--------------------------------------------------------------------#
  #-- Mounts
  #--------------------------------------------------------------------#
  fileSystems."/mnt/games" = {
    device = "/dev/mapper/games";
    fsType = "ext4";
    options = ["nofail" "x-gvfs-show"]; # x-gvfs-show: list in Nautilus's sidebar
  };

  fileSystems."/mnt/games2" = {
    device = "/dev/mapper/games2";
    fsType = "ext4";
    options = ["nofail" "x-gvfs-show"];
  };
}
