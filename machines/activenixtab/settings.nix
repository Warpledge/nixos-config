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
      windowRules = {
        custom-helium-translucent = {
          matches = [{app-id = "^helium$";} {app-id = "^chrome-.*-Default$";}];
          name = "Helium Translucent";
          translucent = true;
        };
        custom-obsidian = {
          matches = [{app-id = "^md\\.obsidian\\.Obsidian$";}];
          name = "Obsidian";
          translucent = true;
        };
      };
      claude.mods.usageBand = false;
      claude.mods.skins = false;
      claude.mods.fileTree = false;
      claude.mods.savvyProgress = false;
      claude.mods.blastRadius = false;
      claude.mods.replayTheater = false;
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
      mangohud.show = ["fps"];
      mangohud.position = "top-right";
      mangohud.fontSize = 16;
      mangohud.textColor = "00FF00";
      mangohud.background = 0;
      gpuOffload = [];
      sideRail = {
        claude-desktop = {
          enable = false;
          order = 2;
        };
        custom-steam = {
          appId = "steam";
          command = ["steam"];
          icon = "steam";
          keepRunning = true;
          name = "Steam";
          order = 1;
          enable = false;
        };
        opencode-desktop = {
          enable = false;
          order = 3;
        };
        terminal = {enable = false;};
      };
      steamGames = {
        "3008130" = {
          launchOptions = "PROTON_NO_FSYNC=1 PROTON_NO_ESYNC=1 PROTON_FSR4_UPGRADE=1 PROTON_FSR4_INDICATOR=1 PROTON_FSR3_UPGRADE=1 MANGOHUD=1 STEAMDECK=1 SteamOS=1 %command%";
          proton = "Proton-CachyOS Latest";
        };
      };
      pi.enable = true;
      gaming.faugus = true;
      gaming.lutris = true;
      media.freetube = true;
      media.ytDlp = true;
      browsers.mullvad = false;
      browsers.ferdium = false;
      editors.helix = true;
      fileBrowsers.nautilus = true;
      fileBrowsers.yazi = true;
      fileBrowsers.duxFiles = false;
      media.videoTrimmer = false;
      media.constrict = false;
      media.moku = false;
      media.streamlinkTwitchGui = false;
      media.boorusama = false;
      media.aniCli = false;
      media.tonkatsuBox = false;
      graphics.blender = false;
      graphics.affinity = false;
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
      audio.guitarix = false;
      audio.tone3000 = false;
      audio.katanaFloorboard = false;
      office.thunderbird = false;
      office.homebank = false;
      security.bleachbit = false;
      system.resources = false;
      fun.cmatrix = false;
      fun.figlet = false;
      fun.ttyper = false;
      dev.rust = false;
      dev.go = false;
      dev.node = false;
      dev.tools = false;
      scrcpy.enable = false;
      androidDev.enable = false;
      gaming.twintail = false;
      gaming.easyrpg = false;
      gaming.feedback = false;
      gaming.rocksmith = false;
      gaming.tmodloader = false;
      gaming.satisfactoryModManager = false;
      gaming.ludusavi = false;
      gaming.granblueRelinkMods = false;
      discord.goofcord = false;
      discord.vesktop = false;
      discord.arrpc.enable = false;
      localAi.edit = null;
      japanese.ime = false;
      japanese.vn = false;
      keybinds = {};
      localAi.models = [];
      localAi.default = null;
      opencode.plugins.usageBar = true;
      opencode.plugins.desktopBar = true;
      opencode.plugins.rebuildBadge = true;
      gaming.omniServer = true;
      claude.mods.rebuildPrompt = false;
      claude.skills.gtnhModUpdates = "on";
      claude.skillModels.gtnhModUpdates = null;
      backups.folder = "~/SyncBackups";
      backups.skip = [];
      opencode.plugins.sessionRail = false;
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
  # default.nix pins zen 7.2.15: 7.3.4 panics at boot on this model
  kernel = "zen";

  #--- Mouse Cursor
  # Options: "bibata" | "catppuccin"
  cursor = "bibata";
  cursorSize = 24;

  #--- Graphics Drivers (Radeon 8060S, no discrete GPU)
  gpu.type = "amd";

  #--------------------------------------------------------------------#
  #-- Local AI Models (served by the user's llamaSwap)
  #--------------------------------------------------------------------#
  #--- The 8060S profile and 120 GiB of GTT replace the ttm kernelParams
  #--- this file's machine used to set by hand (modules: gpu-shared-memory)
  localModels.profile = "strix-halo";
  localModels.gpuSharedGB = 96;
  #--- Ky's two models, from LM Studio's folders; measured in ../local-ai-models.md.
  #--- Upstream serve() puts "-c ctx -np 1 -fa on -ctk/-ctv <cache> --no-webui"
  #--- first, so args below re-set the later-parsed flags (-ctk, -np) and carry
  #--- what serve() has no field for (--mmproj vision, KV pools, MTP drafting).
  #--- Measured with -ctk f16 -ctv q8_0 (q8_0 V cache: ~17% faster prompts)
  localModels.models = {
    nemotron-3_5-super-vl = {
      args = ["-np 3" "--kv-unified-per-slot 65536" "--spec-type draft-mtp" "--top-k 0 --min-p 0" "--mmproj '/home/kylerj/.lmstudio/models/unsloth/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-GGUF/mmproj-BF16.gguf'"];
      batch = 2048;
      cache = "f16";
      category = "code";
      context = 65536;
      dir = "unsloth/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-GGUF";
      fast = {
        chat_template_kwargs = {
          enable_thinking = true;
          medium_effort = true;
        };
        temperature = 1;
        top_p = 0.95;
      };
      match = "NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-UD-Q3_K_XL-00001-of-*.gguf";
      name = "Nemotron 3.5 Super VL";
      think = {
        chat_template_kwargs = {enable_thinking = true;};
        temperature = 1;
        top_p = 0.95;
      };
    };
    qwen3_8-flash-next = {
      args = ["-ctk f16" "--mmproj '/home/kylerj/.lmstudio/models/unsloth/Qwen3.8-Flash-Next-GGUF/mmproj-F16.gguf'"];
      batch = 4096;
      category = "code";
      context = 262144;
      dir = "unsloth/Qwen3.8-Flash-Next-GGUF";
      fast = {
        chat_template_kwargs = {reasoning_effort = "medium";};
        min_p = 0;
        presence_penalty = 0;
        reasoning_effort = "medium";
        temperature = 1;
        top_k = 20;
        top_p = 0.95;
      };
      gpuLayers = "all";
      match = "Qwen3.8-Flash-Next-UD-IQ3_XXS-00001-of-*.gguf";
      name = "Qwen3.8 Flash Next";
      think = {
        chat_template_kwargs = {reasoning_effort = "medium";};
        min_p = 0;
        presence_penalty = 0;
        reasoning_effort = "medium";
        temperature = 1;
        top_k = 20;
        top_p = 0.95;
      };
      mtp = "mtp-Qwen3.8-Flash-Next-Q8_0.gguf";
      draftMax = 4;
    };
  };

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
  blocklist.allow = [];
  apparmor.enforce = [];
  maintenance.clean = "weekly";
  maintenance.keepDays = 5;
  maintenance.keepGenerations = 5;
  maintenance.optimise = "daily";
  maintenance.updateReminderDays = 30;
  printing.enable = true;
  docker.enable = true;
  localModels.backend = "vulkan";
  capsLockRemap = false;
  firewall.openTCPPorts = [];
  firewall.openUDPPorts = [];
  blocklist.enable = false;
  blocklist.extra = [];
  mullvad.enable = false;
  mullvad.splitTunnel = [];
  ssh.enable = false;
  clamav.enable = false;
  suwayomi.enable = false;
  sunshine.enable = false;
  faceAuth.enable = false;
  faceAuth.darkThreshold = 90;
  drives.mounts = [];
}
