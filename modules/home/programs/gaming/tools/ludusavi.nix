#=====================================================================#
# LUDUSAVI - GAME SAVE BACKUPS
#=====================================================================#
#- Daily backup of game saves to ~/SyncBackups/<hostname>/Ludusavi, which
#- Syncthing carries. Settings are declared here, so GUI changes don't persist.
{
  config,
  machine,
  ...
}: let
  backups = "${config.home.homeDirectory}/SyncBackups/${machine.hostName}/Ludusavi";
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
