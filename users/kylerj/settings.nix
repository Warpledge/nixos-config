#=====================================================================#
# KYLERJ'S USER SETTINGS
#=====================================================================#
#- Apps and account settings for kylerj. Everything these switches don't cover
#- is installed from the Apps window into the user profile.
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
    pathOfBuilding = false; # broken in nixpkgs f4a03c0, see disabled-packages.md
    retroshelf = true;
  };

  lmstudio.enable = true;
  #--- Warpledge's llama-swap serves this machine's localModels models
  #--- (machines/activenixtab/settings.nix); the Local Models page tests them
  llamaSwap.enable = true;
  #--- The first is opencode's and Zed's default
  localAi.code = ["qwen3_8-flash-next" "nemotron-3_5-super-vl"];
  localAi.chat = [];
  openWebui.enable = false; # Off until open-webui.nix drops the mcp2 patch (0.12.5 no longer needs it)

  #--------------------------------------------------------------------#
  #-- Window Rules
  #--------------------------------------------------------------------#
  #--- The Apps window shows the wallpaper through at the Mod+Y preset's
  #--- opacity, like the other app windows
  windowRules.custom-ky-apps = {
    matches = [{app-id = "^io\\.github\\.kylerj\\.Apps$";}];
    translucent = true;
  };
}
