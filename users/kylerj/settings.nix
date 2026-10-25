#=====================================================================#
# KYLERJ'S USER SETTINGS
#=====================================================================#
#- Apps and account settings for kylerj. Apps these switches don't cover
#- are in machines/activenixtab/home/apps.nix.
{
  #--------------------------------------------------------------------#
  #-- Account
  #--------------------------------------------------------------------#
  admin = true;

  git = {
    name = "votex09";
    email = "10671494+votex09@users.noreply.github.com";
  };

  ssh.authorizedKeys = [];

  #--------------------------------------------------------------------#
  #-- Apps
  #--------------------------------------------------------------------#
  #--- Default Apps (the browser is Vivaldi, set in machines/activenixtab/home/apps.nix)
  defaultApps = {
    browser = "zen";
    textEditor = "zed";
    terminal = "kitty";
    fileManager = "dolphin";
  };

  browsers.zen = true;
  terminals.kitty = true;
  editors = {
    zed = true;
    vscodium = true;
  };
  fileBrowsers.dolphin = true;

  media = {
    mpv = true;
    spotify = true;
  };

  wallpaper = "carousel";

  graphics.krita = true;
  audio.reaper = true;
  office.obsidian = true;

  gaming = {
    steam = true;
    heroic = true;
    prismlauncher = true;
    r2modman = true;
    pathOfBuilding = true;
    retroshelf = true;
  };

  lmstudio.enable = true;
}
