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

  #--- Window Manager Selection
  # Options: "hyprland" | "niri" | "gnome" | "cosmic"
  windowManager = "niri";

  #--- Kernel Selection
  # Options: "zen" | "latest" | "xanmod" | "cachyos"
  kernel = "cachyos";

  #--- Mullvad VPN
  mullvad.enable = true;
  mullvad.splitTunnel = ["steam" "heroic" "prismlauncher" "claude" "opencode"]; # Apps always routed around the VPN (see shared/modules/mullvad/)

  #--- Browser Selection
  # Enable the browsers you want installed
  browsers = {
    zen = true;
    mullvad = true;
    helium = true;
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
    helix = false;
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
    qrScanner = false; # cobang broken: python-zbar fails to build upstream
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
    reaper = true; # DAW; ships SWS/S&M + ReaPack, JACK routed through PipeWire
    guitar = true; # Amp sims (NeuralRack/Guitarix) + cab IRs; Katana DI capture
  };

  #--- Finance Software Selection
  # Enable the personal finance applications you want installed
  finance = {
    homebank = true; # Lightweight personal accounting (labeled transactions + running balance)
  };

  #--- Locally Installed Packages
  # Prebuilt third-party bundles that aren't in nixpkgs; each is a
  # wrapper around an app kept under ~/.local/opt/ (out of the repo)
  local = {
    granblueRelinkMods = false; # RelinkModOrganizer + Reloaded-II
  };

  #--- Android Container (Waydroid)
  # Run Android apps through Waydroid container
  waydroid = {
    enable = true;
    magisk = false; # Install Magisk for rooting
    nftables = false; # Use nftables instead of iptables
  };

  #--- Android Screen Mirroring (scrcpy)
  # Mirror/control an Android device over USB or wifi; nothing is installed
  # on the device, so it works on de-Googled phones/tablets
  scrcpy.enable = true;

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

  #--- Sunshine Game Streaming
  # Stream games to Moonlight clients (Android, iOS, PC)
  sunshine.enable = false;

  #--- Game Launchers
  # Enable the game launchers you want installed
  gameLaunchers = {
    steam = true; # NixOS programs.steam + GE-Proton
    heroic = true; # Epic / GOG / Amazon
    prismlauncher = true; # Minecraft
    lutris = false; # Wine launcher
    faugus = false; # UMU/Proton launcher
    twintail = false; # Gacha game launcher (Flatpak)
  };

  #--- Discord Rich Presence (arRPC)
  # Standalone arRPC server for Steam/Proton game detection in Vesktop
  discord.arrpc.enable = true;

  #--- Ferdium Messenger Aggregator
  # All web messengers in one window (services configured in-app)
  ferdium.enable = false;

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
