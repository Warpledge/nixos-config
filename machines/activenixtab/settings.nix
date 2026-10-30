#=====================================================================#
# FLOW Z13 MACHINE SETTINGS
#=====================================================================#
#- Machine-wide settings for the ASUS ROG Flow Z13 (GZ302EA). Apps are
#- chosen per user in users/<name>/settings.nix; machines/_template/settings.nix
#- lists every setting this file can hold.
{
  #--------------------------------------------------------------------#
  #-- Users
  #--------------------------------------------------------------------#
  users = {
    kylerj = {
      claude.enable = true;
      claudeDesktop.enable = true;
      opencode.enable = true;
      userPackages = {
        Office = ["audacity_3"];
        Media = ["freetube"];
      };
      security.keepassxc = true;
      wallpaper = "engine";
      terminals.ghostty = true;
      defaultApps.terminal = "ghostty";
      opencodeDesktop.enable = true;
      env = {};
      autostart = {};
      mimeTypes = {};
      windowRules = {};
      claude.mods.ribbon = false;
      claude.mods.skins = false;
      claude.mods.fileTree = false;
      claude.mods.savvyProgress = false;
      claude.mods.blastRadius = false;
      claude.mods.replayTheater = false;
      claude.mods.chatInventory = false;
      claude.mods.screenShare = false;
      claude.statusLine = true;
      claude.builtins.youShouldKnow = true;
      claude.builtins.agentsMd = true;
      claude.builtins.agentsMdFiles = "claude-md-or-agents-md";
      claude.model = null;
      claude.effort = null;
      claude.outputStyle = null;
      claude.plugins.claudeMdManagement = true;
      claude.plugins.skillCreator = true;
      claude.plugins.claudeCodeSetup = true;
      claude.plugins.claudeSecurity = false;
      claude.mcp.nixos = true;
      claude.mcp.context7 = true;
      claude.mcp.github = true;
      claude.mcp.deepwiki = true;
      claude.mcp.grep = true;
      claude.connectors.gmail = true;
      claude.connectors.googleCalendar = true;
      claude.connectors.googleDrive = true;
      claude.connectors.claudeDocs = true;
      claude.accountSkills.builtInBrowser = true;
      claude.accountSkills.chromeBrowser = true;
      claude.accountSkills.computerUse = true;
      claude.accountSkills.deepResearch = true;
      claude.accountSkills.docs = true;
      claude.accountSkills.docx = true;
      claude.accountSkills.googleWorkspace = true;
      claude.accountSkills.importMemory = true;
      claude.accountSkills.mcpBuilder = true;
      claude.accountSkills.morning = true;
      claude.accountSkills.pdf = true;
      claude.accountSkills.pptx = true;
      claude.accountSkills.xlsx = true;
      claude.skills.addApp = "on";
      claude.skills.androidDebloatRedo = "on";
      claude.skills.apparmorCheck = "on";
      claude.skills.commit = "on";
      claude.skills.disablePackage = "on";
      claude.skills.flakeUpdate = "on";
      claude.skills.freetubeSync = "on";
      claude.skills.gameTroubleshooting = "on";
      claude.skills.handoff = "on";
      claude.skills.mokuBump = "on";
      claude.skills.onboard = "on";
      claude.skills.prReview = "on";
      claude.skills.rpgmSetup = "on";
      claude.skills.todo = "on";
      claude.skills.upstream = "on";
      claude.skills.vnSetup = "on";
      claude.skillModels.addApp = null;
      claude.skillModels.androidDebloatRedo = null;
      claude.skillModels.apparmorCheck = null;
      claude.skillModels.commit = null;
      claude.skillModels.disablePackage = null;
      claude.skillModels.flakeUpdate = null;
      claude.skillModels.freetubeSync = null;
      claude.skillModels.gameTroubleshooting = null;
      claude.skillModels.handoff = null;
      claude.skillModels.mokuBump = null;
      claude.skillModels.onboard = null;
      claude.skillModels.prReview = null;
      claude.skillModels.rpgmSetup = null;
      claude.skillModels.todo = null;
      claude.skillModels.upstream = null;
      claude.skillModels.vnSetup = null;
      claude.agents.buildTriager = "on";
      claude.agents.docsDriftAuditor = "on";
      claude.agents.proseReviewer = "on";
      claude.agents.publicRepoAuditor = "on";
      claude.agentModels.buildTriager = null;
      claude.agentModels.docsDriftAuditor = null;
      claude.agentModels.proseReviewer = null;
      claude.agentModels.publicRepoAuditor = null;
      claudeDesktop.matugen = false;
      defaultApps.browser = "helium";
      defaultApps.textEditor = "vscodium";
    };
  };

  mainUser = "kylerj";

  #--------------------------------------------------------------------#
  #-- System (NixOS modules)
  #--------------------------------------------------------------------#
  #--- DO NOT CHANGE (the NixOS 26.05 installer)
  stateVersion = "26.05";
  flakePath = "/home/kylerj/nixos-config";

  #--- Language & Keyboard
  timeZone = "America/Phoenix";
  locale = "en_US.UTF-8";
  keyboardLayout = "us";
  consoleKeyMap = "us";

  #--- Window Manager Selection
  # Options: "niri"
  windowManager = "niri";

  #--- Kernel Selection
  # Options: "zen" | "latest" | "xanmod" | "cachyos"
  # Not cachyos: its 7.0.x builds hang the ASUS WMI controls on this model
  kernel = "zen";

  #--- Mouse Cursor
  # Options: "bibata" | "catppuccin"
  cursor = "bibata";
  cursorSize = 24;

  #--- Graphics Drivers (Radeon 8060S, no discrete GPU)
  gpu.type = "amd";

  #--- Bluetooth
  bluetooth.enable = true;

  #--- Syncthing File Sync
  syncthing.enable = true;

  #--- SMB shares found by server name
  smb.enable = true;

  #--- Flatpak, with Flatseal (RetroDECK)
  flatpak.enable = true;
  boot.menu.timeout = 5;
  boot.menu.entries = 10;
}
