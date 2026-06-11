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
  # Options: "hyprland" | "niri" | "gnome"
  windowManager = "niri";

  #--- Kernel Selection
  # Options: "zen" | "latest" | "xanmod" | "cachyos"
  kernel = "cachyos";

  #--- Mullvad VPN
  mullvad.enable = true;

  #--- Browser Selection
  # Enable the browsers you want installed
  browsers = {
    zen = true;
    mullvad = true;
    helium = false;
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
  };

  #--- Media Selection
  # Enable the media applications you want installed
  media = {
    mpv = true;
    spotify = true;
    grayjay = true;
    videoTrimmer = true;
  };

  #--- Creative Software Selection
  # Enable the creative applications you want installed
  creative = {
    blender = false;
    krita = false;
    affinity = false;
  };

  #--- Android Container (Waydroid)
  # Run Android apps through Waydroid container
  waydroid = {
    enable = false;
    magisk = false; # Install Magisk for rooting
    nftables = false; # Use nftables instead of iptables
  };

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
    lutris = true; # Wine launcher
    faugus = true; # UMU/Proton launcher
    twintail = true; # Gacha game launcher (Flatpak)
  };

  #--- Cohesion Notes (Flatpak)
  # Self-hostable Notion alternative
  cohesion.enable = true;

  #--- AI Tools
  claude = {enable = true;};
  opencode = {enable = true;};
  lmstudio = {enable = false;};

  #--- Japanese Language & Game Support
  # ime: fcitx5 + Mozc input method for typing hiragana/katakana/kanji
  # vn:  raw JP visual novel / game tooling (jp-run locale launcher, extractors)
  japanese = {
    ime = true;
    vn = true;
  };
}
