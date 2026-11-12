#=====================================================================#
# LUDUSAVI - GAME SAVE BACKUPS
#=====================================================================#
#- Daily backup of game saves to <backups.folder>/<hostname>/Ludusavi, which
#- Syncthing carries while that's ~/SyncBackups. Settings are declared here,
#- so GUI changes don't persist.
{
  config,
  lib,
  machine,
  user,
  ...
}: let
  root = import ../../../../../lib/backup-folder.nix {
    inherit lib user;
    home = config.home.homeDirectory;
  };
  backups = "${root}/${machine.hostName}/Ludusavi";
in {
  #--------------------------------------------------------------------#
  #-- Ludusavi Service
  #--------------------------------------------------------------------#
  services.ludusavi = {
    enable = true;
    settings = {
      manifest.url = "https://raw.githubusercontent.com/mtkennerly/ludusavi-manifest/master/data/manifest.yaml";
      roots = [
        {
          path = "~/.local/share/Steam";
          store = "steam";
        }
        {
          path = "~/.config/heroic";
          store = "heroic";
        }
        #--- Faugus and umu prefixes, one drive_c per subfolder
        {
          path = "~/Faugus/*";
          store = "otherWine";
        }
        {
          path = "~/Games/umu/*";
          store = "otherWine";
        }
      ];
      backup.path = backups;
      restore.path = backups;
    };
  };
}
