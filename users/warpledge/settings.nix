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
  # Enable the browsers you want installed
  browsers = {
    zen = true;
    mullvad = true;
    helium = true;
    ferdium = true; # Web messengers in one window (services set in-app)
  };

  #--- Terminal Selection
  # Enable the terminals you want installed
  terminals = {
    kitty = true;
    ghostty = false;
  };

  #--- Editor Selection
  # Enable the editors you want installed
  editors = {
    helix = true;
    zed = true;
  };

  #--- File Browser Selection
  # Enable the file browsers you want installed
  fileBrowsers = {
    nautilus = true;
    yazi = true;
    dolphin = true;
  };

  #--- Default Apps
  defaultApps = {
    browser = "zen";
    textEditor = "zed";
    terminal = "kitty";
    fileManager = "nautilus";
  };

  #--- Media Selection
  # Enable the media applications you want installed
  media = {
    mpv = true;
    spotify = true;
    freetube = true;
    videoTrimmer = true;
    constrict = true; # Compress a video to a target file size
    moku = true; # Manga, novel and anime reader (source build with UI fixes)
    streamlinkTwitchGui = true; # Twitch browser via streamlink + mpv (AppImage)
    boorusama = true; # Booru image board browser (AppImage)

    # Local (~/.local/opt bundles, kept out of git)
    tonkatsuBox = true; # Collection manager (games, film, anime, manga, books)
  };

  #--- Wallpaper Picker: "carousel" | "engine"
  wallpaper = "engine"; # Animated Steam Workshop wallpapers (DP-2/DP-3)

  #--- Graphics Software Selection
  # Enable the graphic design applications you want installed
  graphics = {
    blender = false;
    krita = false;
    affinity = false;
  };

  #--- Audio Software Selection
  # Enable the music and audio applications you want installed
  audio = {
    reaper = true;

    # Guitar rig (Katana DI); any guitar toggle adds shared IR/tuner plugins
    guitarix = true; # Modular amp sim
    tone3000 = true; # Official NAM player with the TONE3000 capture/IR library

    # Local (~/.local/opt bundles, kept out of git)
    katanaFloorboard = true; # Katana MK2 patch editor
  };

  #--- Office Software Selection
  # Enable the office and document applications you want installed
  office = {
    thunderbird = true; # Mail client
    obsidian = true; # Markdown note vaults
    homebank = true; # Simple accounting: labeled transactions + running balance
  };

  #--- Security Software Selection
  # Enable the security and privacy applications you want installed
  security = {
    bleachbit = true; # Disk cleaner for caches, logs and browser leftovers
    keepassxc = true; # Offline password manager (vault synced with Syncthing)
  };

  #--- System Tools Selection
  # Enable the system monitoring applications you want installed
  system = {
    resources = true; # GNOME system and process monitor
  };

  #--- Android Screen Mirroring (scrcpy)
  # Mirror/control an Android device over USB or wifi; nothing is installed
  # on the device, so it works on de-Googled phones/tablets
  scrcpy.enable = true;

  #--- Gaming
  # Enable the game launchers, games and gaming tools you want installed
  gaming = {
    # Launchers
    steam = true; # NixOS programs.steam + GE-Proton
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

    # Tools
    r2modman = true; # Thunderstore mod manager
    pathOfBuilding = true; # Path of Exile build planner (Rusty PoB)
    ludusavi = true; # Daily game save backups to ~/SyncBackups/<host>/Ludusavi

    # Local (~/.local/opt bundles, kept out of git)
    granblueRelinkMods = false; # GBFR mods: RelinkModOrganizer + Reloaded-II
  };

  #--- Discord Rich Presence (arRPC)
  # Standalone arRPC server for Steam/Proton game detection in GoofCord
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
    code = "qwen3.6-35b-a3b-q4";
    edit = "sweep-next-edit-1.5b";
    chat = "gpt-oss-20b";
  };

  #--- Japanese Language & Game Support
  # ime: fcitx5 + Mozc input method for typing hiragana/katakana/kanji
  # vn:  raw JP visual novel / game tooling (jp-run locale launcher, extractors)
  japanese = {
    ime = false;
    vn = false;
  };
}
