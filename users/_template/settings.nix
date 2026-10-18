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
  # Enable the browsers you want installed
  browsers = {
    zen = true;
    mullvad = false;
    helium = false;
    ferdium = false; # Web messengers in one window (services set in-app)
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
    dolphin = false; # KDE's file manager
    yazi = true;
  };

  #--- Media Selection
  # Enable the media applications you want installed
  media = {
    mpv = true;
    spotify = false;
    freetube = false; # Private YouTube client
    videoTrimmer = false;
    constrict = false; # Compress a video to a target file size
    moku = false; # Manga, novel and anime reader (built from source: slow)
    streamlinkTwitchGui = false; # Twitch browser via streamlink + mpv (AppImage)
    boorusama = false; # Booru image board browser (AppImage)

    # Need a prebuilt bundle in ~/.local/opt that this repo doesn't ship
    # (docs/local/local-binary-installs.md)
    tonkatsuBox = false; # Collection manager (games, film, anime, manga, books)
  };

  #--- Wallpaper Picker (Mod+W)
  # "carousel": DMS draws still images from modules/theme/wallpapers
  # "engine": animated Wallpaper Engine wallpapers subscribed on the Steam
  #   Workshop; needs Wallpaper Engine bought and installed in Steam
  wallpaper = "carousel";

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
    reaper = false;

    # Guitar rig; any guitar toggle adds shared IR/tuner plugins
    guitarix = false; # Modular amp sim
    tone3000 = false; # Official NAM player with the TONE3000 capture/IR library

    # Needs a prebuilt bundle in ~/.local/opt (docs/local/local-binary-installs.md)
    katanaFloorboard = false; # BOSS Katana MkII patch editor
  };

  #--- Office Software Selection
  # Enable the office and document applications you want installed
  office = {
    thunderbird = false; # Mail client
    obsidian = false; # Markdown note vaults
    homebank = false; # Simple accounting: labeled transactions + running balance
  };

  #--- Security Software Selection
  # Enable the security and privacy applications you want installed
  security = {
    bleachbit = false; # Disk cleaner for caches, logs and browser leftovers
    keepassxc = false; # Offline password manager
  };

  #--- System Tools Selection
  # Enable the system monitoring applications you want installed
  system = {
    resources = false; # GNOME system and process monitor
  };

  #--- Android Screen Mirroring (scrcpy)
  # Mirror/control an Android device over USB or wifi; nothing is installed
  # on the device, so it works on de-Googled phones/tablets
  scrcpy.enable = false;

  #--- Gaming
  # Enable the game launchers, games and gaming tools you want installed
  gaming = {
    # Launchers
    steam = true; # NixOS programs.steam + GE-Proton
    heroic = false; # Epic / GOG / Amazon
    prismlauncher = false; # Minecraft
    lutris = false; # Wine launcher
    faugus = false; # UMU/Proton launcher
    twintail = false; # Gacha game launcher
    easyrpg = false; # RPG Maker 2000/2003 game interpreter
    xsystem4 = false; # System 4 engine games, native

    # Games
    feedback = false; # Guitar rhythm game, reads Guitar Pro tabs (AppImage)
    rocksmith = false; # Rocksmith 2014 (Steam), set up for a BOSS Katana as input

    # Tools
    r2modman = false; # Thunderstore mod manager
    pathOfBuilding = false; # Path of Exile build planner (Rusty PoB)
    ludusavi = false; # Daily game save backups to ~/SyncBackups/<host>/Ludusavi
    retroshelf = false; # ES-DE / RetroDECK library tidier (AppImage)

    # Needs prebuilt bundles outside the repo (docs/local/local-binary-installs.md)
    granblueRelinkMods = false; # GBFR mods: RelinkModOrganizer + Reloaded-II
  };

  #--- Discord: GoofCord (Vencord), built from source with its own Node.js (slow)
  discord.goofcord = false;

  #--- Discord Rich Presence (arRPC)
  # Standalone arRPC server for Steam/Proton game detection in GoofCord
  discord.arrpc.enable = false;

  #--- AI Tools
  claude.enable = false; # Claude Code (needs an Anthropic account)
  opencode.enable = false;
  lmstudio.enable = false; # Runs language models locally

  #--- Japanese Language & Game Support
  # ime: fcitx5 + Mozc input method for typing hiragana/katakana/kanji
  # vn:  raw JP visual novel / game tooling (jp-run locale launcher, extractors)
  japanese = {
    ime = false;
    vn = false;
  };
}
