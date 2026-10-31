#=====================================================================#
# DESKTOP MACHINE SETTINGS
#=====================================================================#
#- Machine-wide settings for the desktop. Apps are chosen per user in
#- users/<name>/settings.nix; machines/_template/settings.nix lists every
#- setting this file can hold.
{
  #--------------------------------------------------------------------#
  #-- Users
  #--------------------------------------------------------------------#
  users = {
    warpledge = {
      gaming.retroshelf = false;
      fileBrowsers.dolphin = false;
      wallpaper = "engine";
      editors.vscodium = false;
      localAi.chat = ["gemma-4-26b-a4b"];
      localAi.edit = "sweep-next-edit-1.5b";
      media.moku = true;
      media.boorusama = true;
      defaultApps.fileManager = "duxFiles";
      fileBrowsers.nautilus = true;
      fileBrowsers.yazi = false;
      claudeDesktop.enable = true;
      localAi.code = ["ornith-1.5-35b-a3b"];
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
      discord.goofcord = false;
      userPackages = {};
      env = {};
      autostart = {};
      mimeTypes = {};
      scrcpy.enable = false;
      audio.reaper = false;
      audio.guitarix = false;
      dev.go = false;
      dev.node = false;
      dev.rust = false;
      editors.helix = false;
      fileBrowsers.duxFiles = false;
      gaming.satisfactoryModManager = false;
      gaming.r2modman = false;
      gaming.ludusavi = false;
      media.ytDlp = false;
      media.aniCli = false;
      security.keepassxc = false;
      opencodeDesktop.enable = true;
      pi.enable = true;
      openWebui.enable = false;
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
      windowRules = {};
      sideRail = {};
      mangohud.show = ["fps"];
      mangohud.position = "top-right";
      mangohud.fontSize = 16;
      mangohud.textColor = "00FF00";
      mangohud.background = 0;
      gpuOffload = [];
      steamGames = {};
      claude.mods.ribbon = true;
    };
  };

  #--------------------------------------------------------------------#
  #-- System (NixOS modules)
  #--------------------------------------------------------------------#
  #--- DO NOT CHANGE
  stateVersion = "25.11";

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

  #--- Bluetooth
  bluetooth.enable = true;

  #--- Printing (CUPS)
  printing.enable = false;

  #--- Firewall: ports other devices may connect to
  firewall.openTCPPorts = [
    7777 # Terraria server
  ];
  firewall.openUDPPorts = [];

  #--- Ad & Tracker Blocking (Steven Black hosts list)
  blocklist.enable = true;
  blocklist.extra = ["fakenews" "gambling"];

  #--- Mullvad VPN
  mullvad.enable = true;
  # Apps always routed around the VPN (see nixos/security/mullvad/)
  mullvad.splitTunnel = [
    "steam"
    "heroic"
    "prismlauncher"
    "opencode"
    "claude"
    "claude-desktop"
    "lm-studio"
    "spotify"
    "freetube"
    "ferdium"
    "omni-settings"
    "protonplus"
    "nix-daemon"
  ];

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
  suwayomi.enable = true;

  #--- Syncthing File Sync
  # Peer-to-peer sync, web UI at http://127.0.0.1:8384
  syncthing.enable = true;

  #--- Sunshine Game Streaming
  # Streams games to Moonlight clients on the LAN, web UI at https://localhost:47990
  sunshine.enable = false;

  #--- Flatpak (the Hytale launcher), with Flatseal
  flatpak.enable = true;
  smb.enable = false;
  boot.menu.timeout = 5;
  boot.menu.entries = 10;
  apparmor.enforce = ["evince" "file-roller" "katana-floorboard" "mpv" "obsidian" "prismlauncher" "streamlink" "tonkatsu-box" "tsunagu" "unrar" "yt-dlp"];
  blocklist.allow = [];
}
