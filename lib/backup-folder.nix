#=====================================================================#
# BACKUP FOLDER
#=====================================================================#
#- The user's backups.folder as an absolute path, for nixm, Ludusavi and
#- Omni Settings. lib/settings.nix has checked it starts with / or ~/
{
  lib,
  user,
  home,
}: let
  inherit (user.backups) folder;
in
  if lib.hasPrefix "~/" folder
  then home + lib.removePrefix "~" folder
  else folder
