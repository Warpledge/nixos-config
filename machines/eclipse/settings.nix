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
      localAi.chat = ["gemma-4-26b-a4b"];
      localAi.edit = null;
      media.moku = false;
      media.boorusama = true;
      defaultApps.fileManager = "duxFiles";
      fileBrowsers.nautilus = false;
      fileBrowsers.yazi = false;
      claudeDesktop.enable = true;
      localAi.code = ["ornith-1.5-35b-a3b"];
      artcraft.photocraft = true;
      artcraft.lightcraft = true;
      artcraft.vectorcraft = true;
      artcraft.designcraft = true;
      artcraft.figcraft = true;
      artcraft.effectcraft = true;
      artcraft.filmcraft = true;
      artcraft.soundcraft = true;
      artcraft.cadcraft = true;
      artcraft.pdfcraft = true;
      artcraft.wordcraft = true;
      artcraft.gridcraft = true;
      artcraft.deckcraft = true;
      discord.vesktop = true;
      discord.goofcord = false;
      userPackages = {};
      env = {};
      autostart = {};
      mimeTypes = {};
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
}
