#=====================================================================#
# LAPTOP SYSTEM VARIABLES
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Configuration Options
  #--------------------------------------------------------------------#
  # This file contains all host-specific configuration for the laptop system.
  # Edit these values to customize the laptop build.

  #--- Username
  username = "warpledge";

  #--- Window Manager Selection
  # Options: "hyprland" | "niri" | "gnome" | "cosmic"
  windowManager = "niri";

  #--- Kernel Selection
  # Options: "zen" | "latest" | "xanmod" | "cachyos"
  kernel = "cachyos";

  #--- Mullvad VPN
  mullvad.enable = true;
  mullvad.splitTunnel = ["steam" "heroic" "prismlauncher" "opencode" "claude" "vesktop" "spotify" "freetube" "ferdium"]; # Apps always routed around the VPN (see shared/modules/mullvad/)

  #--- Browser Selection
  # Enable the browsers you want installed
  browsers = {
    zen = true;
    mullvad = true;
    helium = true;
    ferdium = true; # All web messengers in one window (services configured in-app)
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
    moku = false; # Manga, novel and anime reader (built from source with UI fixes)
    streamlinkTwitchGui = true; # Twitch browser; streams play in mpv via streamlink (AppImage)
    seanime = false; # Anime and manga media server with a Helium app-window launcher
    boorusama = false; # Booru image board browser (AppImage)
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
    reaper = false; # broken in nixpkgs 151fa4e (SWS + ReaPack fail on GCC 16), see disabled-packages.md
    guitar = true; # Amp sims (TONE3000/Guitarix) + cab IRs; Katana DI capture
    feedback = true; # Guitar rhythm game, reads Guitar Pro tabs (AppImage)
    rocksmith = true; # Rocksmith 2014 (Steam): RS_ASIO + PipeASIO config for the Katana DI
  };

  #--- Office Software Selection
  # Enable the office and document applications you want installed
  office = {
    thunderbird = true; # Mail client
    obsidian = true; # Markdown note vaults
    homebank = true; # Lightweight personal accounting (labeled transactions + running balance)
  };

  #--- Locally Installed Packages
  # Prebuilt third-party bundles that aren't in nixpkgs; each is a
  # wrapper around an app kept under ~/.local/opt/ (out of the repo)
  local = {
    granblueRelinkMods = false; # GBFR mod tools: RelinkModOrganizer (data mods) + Reloaded-II (code/hook mods)
    tonkatsuBox = false; # Collection manager (games, film, anime, manga, books)
    galleryReader = false; # Gallery client (prebuilt Flutter bundle)
  };

  #--- Android Screen Mirroring (scrcpy)
  # Mirror/control an Android device over USB or wifi; nothing is installed
  # on the device, so it works on de-Googled phones/tablets
  scrcpy.enable = true;

  #--- Suwayomi Manga Server
  # Local manga reader, web UI at http://localhost:4567
  suwayomi.enable = false;

  #--- Syncthing File Sync
  # Peer-to-peer sync, web UI at http://127.0.0.1:8384
  syncthing.enable = true;

  #--- Security Software Selection
  # Enable the security and privacy applications you want installed
  security = {
    bleachbit = true; # Disk cleaner for caches, logs and browser leftovers
    keepassxc = true; # Offline password manager (vault synced with Syncthing)
  };

  #--- SSH Server
  # Key-only openssh + fail2ban. Add a public key in
  # shared/modules/nixos/services/ssh.nix before enabling, or there is no way in.
  ssh.enable = false;

  #--- ClamAV Antivirus
  # Enable ClamAV daemon, freshclam auto-updater, and ClamTK GUI
  clamav.enable = false;

  #--- Docker Containerization
  # Enable Docker and Docker Compose for container management
  docker = {
    enable = false;
  };

  #--- WinBoat Windows Runner
  # Run Windows applications on Linux with seamless integration
  winboat = {
    enable = false;
  };

  #--- Game Launchers
  # Enable the game launchers you want installed
  gameLaunchers = {
    steam = true; # NixOS programs.steam + GE-Proton
    heroic = false; # Epic / GOG / Amazon
    prismlauncher = true; # Minecraft
    lutris = false; # Wine launcher
    faugus = false; # UMU/Proton launcher
    twintail = false; # Gacha game launcher (Flatpak)
    easyrpg = false; # RPG Maker 2000/2003 game interpreter
  };

  #--- Gaming Tools
  gamingTools = {
    r2modman = false; # Thunderstore mod manager
    pathOfBuilding = false; # Path of Exile build planner (Rusty PoB)
  };

  #--- Discord Rich Presence (arRPC)
  # Standalone arRPC server for Steam/Proton game detection in Vesktop
  discord.arrpc.enable = false;

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
