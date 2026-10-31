#=====================================================================#
# LAPTOP MACHINE SETTINGS
#=====================================================================#
#- Machine-wide settings for the laptop. Apps are chosen per user in
#- users/<name>/settings.nix; machines/_template/settings.nix lists every
#- setting this file can hold.
{
  #--------------------------------------------------------------------#
  #-- Users
  #--------------------------------------------------------------------#
  users = {
    #--- Off on this machine, on in users/warpledge/settings.nix
    warpledge = {
      media = {
        moku = false;
        boorusama = false;
        tonkatsuBox = false;
      };
      wallpaper = "carousel";
      gaming = {
        heroic = false;
        easyrpg = false;
        r2modman = false;
        pathOfBuilding = false;
        retroshelf = false;
        feedback = false;
        rocksmith = false;
        ludusavi = false;
        tmodloader = false;
        satisfactoryModManager = false;
      };
      discord.arrpc.enable = true;
      lmstudio.enable = false;
      llamaSwap.enable = false;
      opencode.enable = false;
      scrcpy.enable = true;
      audio.reaper = false;
      audio.guitarix = false;
      audio.tone3000 = false;
      audio.katanaFloorboard = false;
      browsers.ferdium = false;
      fileBrowsers.dolphin = false;
      security.keepassxc = false;
      editors.vscodium = false;
      artcraft.photocraft = false;
      artcraft.lightcraft = false;
      artcraft.vectorcraft = false;
      artcraft.designcraft = false;
      artcraft.figcraft = false;
      artcraft.effectcraft = false;
      artcraft.filmcraft = false;
      artcraft.soundcraft = false;
      artcraft.cadcraft = false;
      artcraft.pdfcraft = false;
      artcraft.wordcraft = false;
      artcraft.gridcraft = false;
      artcraft.deckcraft = false;
      discord.vesktop = true;
      userPackages = {};
      keybinds = {};
      androidDev.enable = true;
      fileBrowsers.nautilus = true;
      fileBrowsers.yazi = false;
      discord.goofcord = false;
      localAi.code = [];
      localAi.chat = [];
      localAi.edit = null;
      openWebui.enable = false;
      claudeDesktop.enable = true;
      defaultApps.fileManager = "nautilus";
      claude.plugins.claudeSecurity = false;
      claude.accountSkills.docx = true;
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
      env = {};
      autostart = {};
      mimeTypes = {};
      windowRules = {};
      dev.go = false;
      dev.node = false;
      dev.rust = false;
      fileBrowsers.duxFiles = false;
      opencodeDesktop.enable = false;
    };
  };

  #--------------------------------------------------------------------#
  #-- System (NixOS modules)
  #--------------------------------------------------------------------#
  #--- DO NOT CHANGE
  stateVersion = "26.05";

  #--- Language & Keyboard
  timeZone = "America/Chicago";
  locale = "en_US.UTF-8";
  keyboardLayout = "us";
  consoleKeyMap = "us";

  #--- Caps Lock: Escape when tapped, Ctrl when held
  capsLockRemap = true;

  #--- Window Manager Selection
  # Options: "niri"
  windowManager = "niri";

  #--- Kernel Selection
  # Options: "zen" | "latest" | "xanmod" | "cachyos"
  kernel = "zen";

  #--- Mouse Cursor
  # Options: "bibata" | "catppuccin"
  cursor = "bibata";
  cursorSize = 24;

  #--- Local AI Models: llama.cpp on the RTX 4070 through CUDA
  localModels.backend = "cuda";
  localModels.profile = "rtx-4070-laptop";

  #--- Bluetooth
  bluetooth.enable = false;

  #--- Battery Charge Limit (conservation mode on this Lenovo)
  battery.chargeLimit = 80;

  #--- Printing (CUPS)
  printing.enable = false;

  #--- Firewall: ports other devices may connect to
  firewall.openTCPPorts = [
    7777 # Terraria server
  ];
  firewall.openUDPPorts = [];

  #--- Ad & Tracker Blocking (Steven Black hosts list)
  blocklist.enable = true;
  blocklist.extra = ["fakenews" "gambling" "porn"];

  #--- Mullvad VPN
  mullvad.enable = true;
  # Apps always routed around the VPN (see nixos/security/mullvad/)
  mullvad.splitTunnel = ["steam" "heroic" "prismlauncher" "opencode" "claude" "spotify" "freetube" "ferdium" "omni-settings" "protonplus" "nix-daemon" "claude-desktop" "lm-studio"];

  #--- SSH Server
  # Key-only openssh + fail2ban. Add a public key to ssh.authorizedKeys in
  # users/<name>/settings.nix before enabling, or there is no way in.
  ssh.enable = false;

  #--- ClamAV Antivirus
  # Background scanner, definition updates and the ClamTK window
  clamav.enable = false;

  #--- Docker Containerization
  # Docker and Docker Compose; admins join the docker group
  docker = {
    enable = false;
  };

  #--- Suwayomi Manga Server
  # Local manga reader, web UI at http://localhost:4567
  suwayomi.enable = false;

  #--- Syncthing File Sync
  # Peer-to-peer sync, web UI at http://127.0.0.1:8384
  syncthing.enable = true;

  #--- Sunshine Game Streaming
  # Streams games to Moonlight clients on the LAN, web UI at https://localhost:47990
  sunshine.enable = false;

  #--- Flatpak, with Flatseal
  flatpak.enable = false;
  smb.enable = false;
  boot.menu.timeout = 5;
  boot.menu.entries = 10;
}
