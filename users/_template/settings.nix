#=====================================================================#
# USER SETTINGS (TEMPLATE)
#=====================================================================#
#- A new person gets a copy of this folder at users/<username>/, where
#- <username> is their login name. Running ./setup.sh add-user makes the
#- copy, asks the questions below and adds them to a machine (machines/
#- <name>/settings.nix lists who can log in there).
#-
#- This file also lists every user setting there is. Anything your copy
#- leaves out is off (false), empty or null. An app set to true is
#- installed and configured for this person only.
{
  #--------------------------------------------------------------------#
  #-- Account
  #--------------------------------------------------------------------#
  #--- Can use sudo and rebuild the system. false for a child's or a
  #--- guest's account.
  admin = true;

  #--- Name and email on git commits; a null name uses the login name
  git = {
    name = null;
    email = null;
  };

  #--- Public keys that may log in over SSH while the machine has
  #--- ssh.enable on. A public key is not a secret, so it can live here.
  ssh.authorizedKeys = [];

  #--------------------------------------------------------------------#
  #-- Apps
  #--------------------------------------------------------------------#
  #--- Default Apps
  # Which app opens web links, text files, terminal programs and folders. One
  # that's turned off below is skipped for the first of its kind that's on.
  defaultApps = {
    browser = "zen";
    textEditor = "zed";
    terminal = "kitty";
    fileManager = "nautilus";
  };

  #--- Browser Selection
  browsers = {
    zen = true;
    mullvad = false;
    helium = false;
    ferdium = false; # Web messengers in one window (services set in-app)
  };

  #--- Terminal Selection
  terminals = {
    kitty = true;
    ghostty = false;
  };

  #--- Editor Selection
  editors = {
    helix = true;
    zed = true;
    vscodium = false; # VS Code without telemetry
  };

  #--- File Browser Selection
  fileBrowsers = {
    nautilus = true;
    dolphin = false; # KDE's file manager
    yazi = true;
    duxFiles = false; # Dux Labs file manager
  };

  #--- Media Selection
  media = {
    mpv = true;
    spotify = false;
    freetube = false; # Private YouTube client
    videoTrimmer = false;
    constrict = false; # Compress a video to a target file size
    moku = false; # Manga, novel and anime reader (built from source: slow)
    streamlinkTwitchGui = false; # Twitch browser via streamlink + mpv (AppImage)
    boorusama = false; # Booru image board browser (AppImage)
    ytDlp = false; # Download video and audio from YouTube and other sites
    aniCli = false; # Browse and play anime from the terminal

    # Need a prebuilt bundle in ~/.local/opt that this repo doesn't ship
    # (docs/personal/local/local-binary-installs.md)
    tonkatsuBox = false; # Collection manager (games, film, anime, manga, books)
  };

  #--- Wallpaper Picker (Mod+W)
  # "carousel": DMS draws still images from modules/theme/wallpapers
  # "engine": animated Wallpaper Engine wallpapers subscribed on the Steam
  #   Workshop; needs Wallpaper Engine bought and installed in Steam
  wallpaper = "carousel";

  #--- Graphics Software Selection
  graphics = {
    blender = false;
    krita = false;
    affinity = false;
  };

  #--- ArtCraft
  # Rust creative and office suite
  artcraft = {
    photocraft = false; # Layered photo editor (PSD)
    lightcraft = false; # Non-destructive RAW editor
    vectorcraft = false; # Vector art and SVG
    designcraft = false; # Page layout and print design
    figcraft = false; # Interface design and prototyping
    effectcraft = false; # Motion graphics and compositing
    filmcraft = false; # Nonlinear video editor
    soundcraft = false; # Audio recording and editing
    cadcraft = false; # CAD and drafting
    pdfcraft = false; # PDF reader and editor
    wordcraft = false; # Word processor
    gridcraft = false; # Spreadsheet
    deckcraft = false; # Presentations
  };

  #--- Audio Software Selection
  audio = {
    reaper = false;

    # Guitar rig; any guitar toggle adds shared IR/tuner plugins
    guitarix = false; # Modular amp sim
    tone3000 = false; # Official NAM player with the TONE3000 capture/IR library

    # Needs a prebuilt bundle in ~/.local/opt
    # (docs/personal/local/local-binary-installs.md)
    katanaFloorboard = false; # BOSS Katana MkII patch editor
  };

  #--- Office Software Selection
  office = {
    thunderbird = false; # Mail client
    obsidian = false; # Markdown note vaults
    homebank = false; # Simple accounting: labeled transactions + running balance
  };

  #--- Security Software Selection
  security = {
    bleachbit = false; # Disk cleaner for caches, logs and browser leftovers
    keepassxc = false; # Offline password manager
  };

  #--- System Tools Selection
  system = {
    resources = false; # GNOME system and process monitor
  };

  #--- Fun
  fun = {
    cmatrix = false; # The Matrix's falling characters in the terminal
    figlet = false; # Big letters made out of ordinary text
    ttyper = false; # Terminal typing test
  };

  #--- Dev
  dev = {
    rust = false; # Rust through rustup; run `rustup default stable` once
    go = false; # Go compiler and tools
    node = false; # Node.js and npm
    tools = false; # gdb, make, lazygit, onefetch, ilspycmd
  };

  #--- Android
  # scrcpy: mirror and control an Android device over USB or wifi; nothing is
  # installed on it
  scrcpy.enable = false;
  androidDev.enable = false; # adb, Flutter, Gradle and the Android SDK paths

  #--- Gaming
  gaming = {
    # Launchers
    steam = true; # NixOS programs.steam
    heroic = false; # Epic / GOG / Amazon
    prismlauncher = false; # Minecraft
    lutris = false; # Wine launcher
    faugus = false; # UMU/Proton launcher
    twintail = false; # Gacha game launcher
    easyrpg = false; # RPG Maker 2000/2003 game interpreter

    # Games
    feedback = false; # Guitar rhythm game, reads Guitar Pro tabs (AppImage)
    rocksmith = false; # Rocksmith 2014 (Steam), set up for a BOSS Katana as input
    tmodloader = false; # tml-prelaunch runtime patch, .NET 8 and Mono

    # Tools
    r2modman = false; # Thunderstore mod manager
    satisfactoryModManager = false; # Satisfactory mod manager
    pathOfBuilding = false; # Path of Exile build planner (Rusty PoB)
    ludusavi = false; # Daily game save backups to ~/SyncBackups/<host>/Ludusavi
    retroshelf = false; # ES-DE / RetroDECK library tidier

    # Needs prebuilt bundles outside the repo
    # (docs/personal/local/local-binary-installs.md)
    granblueRelinkMods = false; # GBFR mods: RelinkModOrganizer + Reloaded-II
  };

  #--- Discord: GoofCord (Vencord), built from source with its own Node.js (slow)
  discord.goofcord = false;
  #--- Discord: Vesktop (Vencord), recolours live with the DMS theme (slow first build)
  discord.vesktop = false;

  #--- Discord Rich Presence (arRPC)
  # Shows the Steam or Proton game you're playing in GoofCord or Vesktop
  discord.arrpc.enable = false;

  #--- AI Tools
  claude.enable = false; # Claude Code (needs an Anthropic account)
  claude.mods.ribbon = false; # Band above Claude Code's prompt: usage left, prompt cache
  claude.mods.skins = false; # Skins: cards, tool rows and a wallpaper-coloured skin
  claude.mods.fileTree = false; # File tree sidebar (needs /tui fullscreen in a terminal)
  claude.mods.savvyProgress = false; # Progress bar and a live panel of subagents
  claude.mods.blastRadius = false; # Shows what a risky rm or git command would change
  claude.mods.replayTheater = false; # /replay steps through the last turn's edits
  # Need BenAI's mods unzipped into ~/.local/opt/claude-mods
  claude.mods.chatInventory = false; # Pane listing the chat's to-dos, files and tools
  claude.mods.screenShare = false; # /screen-share hides names and emails while recording
  claude.statusLine = false; # Status line under Claude Code's prompt: context used
  claude.builtins.youShouldKnow = false; # Built-in "you should know" plugin
  claude.builtins.agentsMd = true; # Built-in plugin that reads AGENTS.md files
  claude.builtins.agentsMdFiles = "claude-md-or-agents-md"; # Files it loads
  claudeDesktop.enable = false; # Claude desktop app: chat and Claude Code
  claudeDesktop.matugen = false; # Claude desktop app in your wallpaper's colours
  opencode.enable = false;
  opencodeDesktop.enable = false; # OpenCode's desktop app: a Claude Desktop-style GUI
  lmstudio.enable = false; # Runs language models locally
  llamaSwap.enable = false; # llama.cpp server on the GPU, opencode's default model
  openWebui.enable = false; # Chat with llama-swap's models in the browser
  # Models llama-swap serves, from the names in lib/local-models.nix. Each app
  # lists the ones turned on; the first coding model is opencode's and Zed's default
  localAi = {
    code = []; # Coding models
    edit = null; # Zed's inline suggestions
    chat = []; # Chat models
  };

  #--- Claude Code Settings
  # Written into ~/.claude/settings.json; changes made inside Claude Code stay
  # until a rebuild changes the same setting here. null leaves it to Claude Code.
  claude.model = null;
  claude.effort = null;
  claude.outputStyle = null;
  #--- Claude Code Plugins
  claude.plugins.claudeMdManagement = true;
  claude.plugins.skillCreator = true;
  claude.plugins.claudeCodeSetup = true;
  claude.plugins.claudeSecurity = false; # Lists 9 agents every session; scans cost a lot
  #--- MCP Servers (Claude Code and OpenCode)
  claude.mcp.nixos = true;
  claude.mcp.context7 = true;
  claude.mcp.github = true;
  claude.mcp.deepwiki = true;
  claude.mcp.grep = true;
  #--- claude.ai Connectors
  claude.connectors.gmail = true;
  claude.connectors.googleCalendar = true;
  claude.connectors.googleDrive = true;
  claude.connectors.claudeDocs = true;
  #--- Account Skills
  # Skills synced from your claude.ai account
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
  #--- Repo Skills
  # on, name-only, user-invocable-only or off; a model of null keeps the skill's own
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
  #--- Subagents
  claude.agents.buildTriager = "on";
  claude.agents.docsDriftAuditor = "on";
  claude.agents.proseReviewer = "on";
  claude.agents.publicRepoAuditor = "on";
  claude.agentModels.buildTriager = null;
  claude.agentModels.docsDriftAuditor = null;
  claude.agentModels.proseReviewer = null;
  claude.agentModels.publicRepoAuditor = null;

  #--- Japanese Language & Game Support
  # ime: fcitx5 + Mozc input method for typing hiragana/katakana/kanji
  # vn:  raw JP visual novel / game tooling (jp-run locale launcher, extractors)
  japanese = {
    ime = false;
    vn = false;
  };

  #--------------------------------------------------------------------#
  #-- Startup
  #--------------------------------------------------------------------#
  #--- Environment Variables
  # Variables every program you start sees, e.g. {EDITOR = "zeditor";}
  env = {};

  #--- Autostart
  # Programs started with the desktop, as command lists, e.g.
  # {syncthing = ["syncthing" "--no-browser"];}
  autostart = {};

  #--------------------------------------------------------------------#
  #-- File Types
  #--------------------------------------------------------------------#
  #--- File Type Overrides
  # Which app opens one file type, in front of defaultApps, e.g.
  # {"application/x-cbz" = "moku.desktop";}
  mimeTypes = {};

  #--- Run on the dGPU
  # Apps whose launcher entry starts them with nvidia-offload, by .desktop id,
  # set on Omni Settings' Hardware tab: ["steam.desktop"]. Hybrid laptops only
  gpuOffload = [];

  #--- User Packages
  # nixpkgs packages added from Omni Settings' Packages tab, installed as they
  # come with no settings of their own, sorted into categories you name,
  # e.g. {Office = ["obsidian"]; Media = ["kdePackages.kdenlive"];}
  userPackages = {};

  #--- Keybinds
  # Changes to the config's niri keybinds, made on Omni Settings' Keybinds page,
  # by bind id: {terminal = {key = "Mod+Alt+T";}; steam = {enable = false;};}.
  # Your own binds have ids starting custom-, a key, a title, and spawn (a
  # command as a list) or a niri action with an optional argument.
  keybinds = {};

  #--- Window Rules
  # Changes to the config's niri window rules, made on Omni Settings' Window
  # Rules page, by rule id: {minecraft-fullscreen = {enable = false;};}, or a
  # whole rule in its place. Your own rules have ids starting custom-.
  windowRules = {};

  #--- Side Rail
  # Changes to the Mod+A side rail's apps, made on Omni Settings' Side Rail
  # page, by id: {brave-ai = {enable = false;}; terminal = {width = 900;};}.
  # keepRunning = true keeps an app open while hidden; otherwise it closes
  # after unloadAfter minutes hidden (30 unless set).
  # Your own apps have ids starting custom-, a name, an optional icon, and a
  # url (opened as a Helium app window) or a command (a list) and its appId.
  sideRail = {};
}
