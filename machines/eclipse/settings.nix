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
      wallpaper = "carousel";
      editors.vscodium = false;
      localAi.models = [];
      localAi.edit = null;
      media.moku = true;
      media.boorusama = true;
      defaultApps.fileManager = "duxFiles";
      fileBrowsers.nautilus = true;
      fileBrowsers.yazi = false;
      claudeDesktop.enable = true;
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
      scrcpy.enable = true;
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
      steamGames = {
        "438130" = {launchOptions = "nix-vn-720p %command%";};
        "948740" = {launchOptions = "nix-vn-1080p %command%";};
        "1698960" = {launchOptions = "";};
        "4256180" = {launchOptions = "nix-vn-768p %command%";};
        "4732690" = {launchOptions = "PROTON_LOG=1 ENABLE_LAYER_MESA_ANTI_LAG=1 nix-performance %command%";};
      };
      claude.mods.ribbon = true;
      keybinds = {};
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

  #--- Local AI Models
  localModels.profile = "rx-9070-xt";

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
  maintenance.clean = "weekly";
  maintenance.keepDays = 5;
  maintenance.keepGenerations = 5;
  maintenance.optimise = "daily";
  maintenance.updateReminderDays = 30;
  localModels.models = {
    flint = {
      batch = 1024;
      cache = "q8_0";
      context = 262144;
      cpuMoe = 33;
      dir = "unsloth/flint-GGUF";
      gpuLayers = "all";
      match = "flint-UD-Q4_K_XL.gguf";
      name = "flint";
    };
    gemma-4-12b-it-qat = {
      batch = 2048;
      cache = "q8_0";
      context = 262144;
      dir = "unsloth/gemma-4-12B-it-qat-GGUF";
      gpuLayers = "all";
      match = "gemma-4-12B-it-qat-UD-Q4_K_XL.gguf";
      name = "gemma 4 12B it qat";
    };
    gemma-4-26b-a4b = {
      batch = 2048;
      cache = "q8_0";
      context = 262144;
      cpuMoe = 10;
      gpuLayers = "all";
      loadMode = "none";
    };
    "ornith-1.5-35b-a3b" = {
      batch = 2048;
      cache = "q8_0";
      cacheRam = 4096;
      context = 262144;
      cpuMoe = 22;
      gpuLayers = "all";
      loadMode = "none";
    };
    "ornith-1.5-35b-a3b-apex-mtp-i-mini" = {
      dir = "mudler/Ornith-1.5-35B-A3B-APEX-MTP-GGUF";
      match = "Ornith-1.5-35B-A3B-APEX-MTP-I-Mini.gguf";
      name = "Ornith 1.5 35B A3B APEX MTP I Mini";
      mmproj = "mmproj.gguf";
      context = 131072;
      cache = "f16";
      batch = 4096;
      cacheRam = 16384;
      gpuLayers = "all";
      cpuMoe = 10;
    };
    "qwen3.8-27b" = {
      batch = 2048;
      cache = "q4_0";
      cacheRam = 16384;
      context = 131072;
      dir = "unsloth/Qwen3.8-27B-GGUF";
      gpuLayers = 49;
      match = "Qwen3.8-27B-UD-Q4_K_M.gguf";
      name = "Qwen3.8 27B";
    };
    "qwen3.8-27b-q2" = {
      cache = "q4_0";
      cacheRam = 16384;
      context = 131072;
      dir = "unsloth/Qwen3.8-27B-GGUF";
      gpuLayers = "all";
      match = "Qwen3.8-27B-UD-Q2_K_XL.gguf";
      mmproj = "mmproj-F16.gguf";
      mtp = "mtp-Qwen3.8-27B-Q4_0.gguf";
      name = "Qwen3.8 27B Q2";
    };
    "qwen3.8-27b-q3" = {
      cache = "q4_0";
      cacheRam = 16384;
      context = 32768;
      dir = "unsloth/Qwen3.8-27B-GGUF";
      gpuLayers = "all";
      match = "Qwen3.8-27B-UD-Q3_K_XL.gguf";
      mtp = "mtp-Qwen3.8-27B-Q4_0.gguf";
      name = "Qwen3.8 27B Q3";
    };
  };
  localModels.backend = "vulkan";
}
