#=====================================================================#
# DESKTOP SYSTEM VARIABLES
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Configuration Options
  #--------------------------------------------------------------------#
  # This file contains all host-specific configuration for the desktop system.
  # Edit these values to customize the desktop build.

  #--- Username
  username = "warpledge";

  #--------------------------------------------------------------------#
  #-- System (NixOS modules)
  #--------------------------------------------------------------------#
  #--- Window Manager Selection
  # Options: "hyprland" | "niri"
  windowManager = "niri";

  #--- Kernel Selection
  # Options: "zen" | "latest" | "xanmod" | "cachyos"
  kernel = "cachyos";

  #--- Mullvad VPN
  mullvad.enable = true;
  # Apps always routed around the VPN (see nixos/security/mullvad/)
  mullvad.splitTunnel = [
    "steam"
    "heroic"
    "prismlauncher"
    "opencode"
    "claude"
    "spotify"
    "freetube"
    "ferdium"
  ];

  #--- SSH Server
  # Key-only openssh + fail2ban. Add a public key in nixos/services/ssh.nix
  # before enabling, or there is no way in.
  ssh.enable = false;

  #--- ClamAV Antivirus
  # Enable ClamAV daemon, freshclam auto-updater, and ClamTK GUI
  clamav.enable = false;

  #--- Docker Containerization
  # Enable Docker and Docker Compose for container management
  docker = {
    enable = false;
  };

  #--- Suwayomi Manga Server
  # Local manga reader, web UI at http://localhost:4567
  suwayomi.enable = true;

  #--- Syncthing File Sync
  # Peer-to-peer sync, web UI at http://127.0.0.1:8384
  syncthing.enable = true;

  #--------------------------------------------------------------------#
  #-- Home (home-manager modules)
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
  };

  #--- Media Selection
  # Enable the media applications you want installed
  media = {
    mpv = true;
    spotify = true;
    freetube = true;
    videoTrimmer = true;
    moku = true; # Manga, novel and anime reader (source build with UI fixes)
    streamlinkTwitchGui = true; # Twitch browser via streamlink + mpv (AppImage)
    seanime = true; # Anime/manga media server, opens as a Helium app window
    boorusama = true; # Booru image board browser (AppImage)

    # Local (~/.local/opt bundles, kept out of git)
    tonkatsuBox = true; # Collection manager (games, film, anime, manga, books)
  };

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
    reaper = false; # SWS + ReaPack broken on GCC 16, see disabled-packages.md

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
    hytale = true; # Enables Flatpak; official launcher installed by hand
    easyrpg = true; # RPG Maker 2000/2003 game interpreter

    # Games
    feedback = true; # Guitar rhythm game, reads Guitar Pro tabs (AppImage)
    rocksmith = true; # Rocksmith 2014 (Steam), RS_ASIO + PipeASIO on Katana DI

    # Tools
    r2modman = true; # Thunderstore mod manager
    pathOfBuilding = true; # Path of Exile build planner (Rusty PoB)

    # Local (~/.local/opt bundles, kept out of git)
    granblueRelinkMods = false; # GBFR mods: RelinkModOrganizer + Reloaded-II
  };

  #--- Discord Rich Presence (arRPC)
  # Standalone arRPC server for Steam/Proton game detection in Vesktop
  discord.arrpc.enable = true;

  #--- AI Tools
  claude = {enable = true;};
  opencode = {enable = true;};
  lmstudio = {enable = true;};

  #--- Japanese Language & Game Support
  # ime: fcitx5 + Mozc input method for typing hiragana/katakana/kanji
  # vn:  raw JP visual novel / game tooling (jp-run locale launcher, extractors)
  japanese = {
    ime = false;
    vn = false;
  };
}
