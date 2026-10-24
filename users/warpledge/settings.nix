#=====================================================================#
# WARPLEDGE'S USER SETTINGS
#=====================================================================#
#- Apps and account settings for warpledge, on every machine that lists
#- this user. A machine's own settings.nix can change any of these for
#- that machine only (the laptop turns several off).
{
  #--------------------------------------------------------------------#
  #-- Account
  #--------------------------------------------------------------------#
  admin = true;

  git = {
    name = "warpledge";
    email = "168894871+Warpledge@users.noreply.github.com";
  };

  #--- Public keys allowed to log in while a machine has ssh.enable on; a
  #--- public key is not a secret, so it belongs in the repo
  ssh.authorizedKeys = [
  ];

  #--------------------------------------------------------------------#
  #-- Apps
  #--------------------------------------------------------------------#
  #--- Browser Selection
  browsers = {
    zen = true;
    mullvad = true;
    helium = true;
    ferdium = true; # Web messengers in one window (services set in-app)
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
  };

  #--- File Browser Selection
  fileBrowsers = {
    nautilus = true;
    yazi = true;
    dolphin = true;
    duxFiles = true;
  };

  #--- Default Apps
  defaultApps = {
    browser = "zen";
    textEditor = "zed";
    terminal = "kitty";
    fileManager = "nautilus";
  };

  #--- Media Selection
  media = {
    mpv = true;
    spotify = true;
    freetube = true;
    videoTrimmer = true;
    constrict = true; # Compress a video to a target file size
    moku = true; # Manga, novel and anime reader (source build with UI fixes)
    streamlinkTwitchGui = true; # Twitch browser via streamlink + mpv (AppImage)
    boorusama = true; # Booru image board browser (AppImage)
    ytDlp = true; # Download video and audio from YouTube and other sites
    aniCli = true; # Browse and play anime from the terminal

    # Local (~/.local/opt bundles, kept out of git)
    tonkatsuBox = true; # Collection manager (games, film, anime, manga, books)
  };

  #--- Wallpaper Picker: "carousel" | "engine"
  wallpaper = "engine"; # Animated Steam Workshop wallpapers (DP-2/DP-3)

  #--- Graphics Software Selection
  graphics = {
    blender = false;
    krita = false;
    affinity = false;
  };

  #--- Audio Software Selection
  audio = {
    reaper = true;

    # Guitar rig (Katana DI); any guitar toggle adds shared IR/tuner plugins
    guitarix = true; # Modular amp sim
    tone3000 = true; # Official NAM player with the TONE3000 capture/IR library

    # Local (~/.local/opt bundles, kept out of git)
    katanaFloorboard = true; # Katana MK2 patch editor
  };

  #--- Office Software Selection
  office = {
    thunderbird = true; # Mail client
    obsidian = true; # Markdown note vaults
    homebank = true; # Simple accounting: labeled transactions + running balance
  };

  #--- Security Software Selection
  security = {
    bleachbit = true; # Disk cleaner for caches, logs and browser leftovers
    keepassxc = true; # Offline password manager (vault synced with Syncthing)
  };

  #--- System Tools Selection
  system = {
    resources = true; # GNOME system and process monitor
  };

  #--- Fun
  fun = {
    cmatrix = true; # The Matrix's falling characters in the terminal
    figlet = true; # Big letters made out of ordinary text
    ttyper = true; # Terminal typing test
  };

  #--- Dev
  dev = {
    rust = true; # Rust through rustup; run `rustup default stable` once
    go = true; # Go compiler and tools
    node = true; # Node.js and npm
    tools = true; # gdb, make, lazygit, onefetch, ilspycmd
  };

  #--- Android
  # scrcpy: mirror and control an Android device over USB or wifi; nothing is
  # installed on it
  scrcpy.enable = true;
  androidDev.enable = true; # adb, Flutter, Gradle and the Android SDK paths

  #--- Gaming
  gaming = {
    # Launchers
    steam = true; # NixOS programs.steam
    heroic = true; # Epic / GOG / Amazon
    prismlauncher = true; # Minecraft
    lutris = false; # Wine launcher
    faugus = true; # UMU/Proton launcher
    twintail = false; # Gacha game launcher
    easyrpg = true; # RPG Maker 2000/2003 game interpreter
    xsystem4 = true; # Wonderland Soft System 4 engine (Lance 7), native

    # Games
    feedback = true; # Guitar rhythm game, reads Guitar Pro tabs (AppImage)
    rocksmith = true; # Rocksmith 2014 (Steam), RS_ASIO + PipeASIO on Katana DI
    tmodloader = true; # tml-prelaunch runtime patch, .NET 8 and Mono

    # Tools
    r2modman = true; # Thunderstore mod manager
    satisfactoryModManager = true; # Satisfactory mod manager
    pathOfBuilding = true; # Path of Exile build planner (Rusty PoB)
    ludusavi = true; # Daily game save backups to ~/SyncBackups/<host>/Ludusavi

    # Local (~/.local/opt bundles, kept out of git)
    granblueRelinkMods = false; # GBFR mods: RelinkModOrganizer + Reloaded-II
  };

  #--- Discord Rich Presence (arRPC)
  # Shows the Steam or Proton game you're playing in GoofCord or Vesktop
  discord.goofcord = true;
  discord.arrpc.enable = true;

  #--- AI Tools
  claude = {enable = true;};
  claudeDesktop = {enable = true;};
  opencode = {enable = true;};
  lmstudio = {enable = true;};
  llamaSwap = {enable = true;};
  openWebui = {enable = true;};
  localAi = {
    code = ["ornith-1.5-35b-a3b" "qwen3.6-35b-a3b-q4"];
    edit = "sweep-next-edit-1.5b";
    chat = ["gpt-oss-20b" "gemma-4-26b-a4b"];
  };

  #--- Japanese Language & Game Support
  # ime: fcitx5 + Mozc input method for typing hiragana/katakana/kanji
  # vn:  raw JP visual novel / game tooling (jp-run locale launcher, extractors)
  japanese = {
    ime = false;
    vn = false;
  };
}
