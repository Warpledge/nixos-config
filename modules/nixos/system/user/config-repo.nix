#=====================================================================#
# SHARED CONFIG REPO
#=====================================================================#
{
  lib,
  machine,
  ...
}: let
  path = machine.flakePath;
in {
  #--------------------------------------------------------------------#
  #-- Repo Access
  #--------------------------------------------------------------------#
  #--- Every admin (wheel) may edit the repo. The default ACL keeps files any of
  #--- them creates writable by the others, whatever their umask. Skipped for a
  #--- repo kept in a home folder, which other users can't enter.
  systemd.tmpfiles.rules = lib.mkIf (!lib.hasPrefix "/home/" path) [
    "d ${path} 2775 ${machine.mainUser} wheel -"
    "A+ ${path} - - - - group:wheel:rwX,default:group:wheel:rwX"
  ];

  #--- Git refuses a repo owned by another user without this
  programs.git = {
    enable = true;
    config.safe.directory = path;
  };
}
