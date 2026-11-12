#=====================================================================#
# DRIVES MOUNTED AT STARTUP (drives.mounts IN THE MACHINE'S SETTINGS.NIX)
#=====================================================================#
{
  config,
  lib,
  machine,
  ...
}: let
  #--- These have no owners of their own, so the mount gives them to the users group
  ownerless = ["vfat" "exfat" "ntfs"];
in {
  #--------------------------------------------------------------------#
  #-- Mounts
  #--------------------------------------------------------------------#
  #--- nofail and the short timeout: a missing drive can't hold up boot
  fileSystems = lib.listToAttrs (map (m:
    lib.nameValuePair m.mountPoint {
      device = "/dev/disk/by-uuid/${m.uuid}";
      fsType =
        if m.fsType == "ntfs"
        then "ntfs3"
        else m.fsType;
      options =
        ["nofail" "x-systemd.device-timeout=10s" "x-gvfs-show"]
        ++ lib.optionals (lib.elem m.fsType ownerless)
        ["gid=${toString config.users.groups.users.gid}" "umask=002"];
    })
  machine.drives.mounts);
}
