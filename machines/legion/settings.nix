#=====================================================================#
# LAPTOP MACHINE SETTINGS
#=====================================================================#
#- Machine-wide settings for the laptop. Apps are chosen per user in
#- users/<name>/settings.nix; machines/_template/settings.nix lists every
#- setting this file can hold.
{
  #--------------------------------------------------------------------#
  #-- Users
  #--------------------------------------------------------------------#
  users = {
    #--- Off on this machine, on in users/warpledge/settings.nix
    warpledge = {
      media = {
        moku = false;
        boorusama = false;
        tonkatsuBox = false;
      };
      wallpaper = "engine";
      gaming = {
        heroic = false;
        easyrpg = false;
        xsystem4 = false;
        r2modman = false;
        pathOfBuilding = false;
        retroshelf = false;
        feedback = false;
        rocksmith = false;
        ludusavi = false;
      };
      discord.arrpc.enable = false;
      lmstudio.enable = false;
      llamaSwap.enable = false;
      opencode.enable = false;
      scrcpy.enable = false;
      audio.reaper = false;
      audio.guitarix = false;
      audio.tone3000 = false;
      audio.katanaFloorboard = false;
      browsers.ferdium = false;
      fileBrowsers.dolphin = false;
      security.keepassxc = false;
    };
  };

  #--------------------------------------------------------------------#
  #-- System (NixOS modules)
  #--------------------------------------------------------------------#
  #--- DO NOT CHANGE
  stateVersion = "26.05";

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
  bluetooth.enable = false;

  #--- Printing (CUPS)
  printing.enable = false;

  #--- Firewall: ports other devices may connect to
  firewall.openTCPPorts = [
    7777 # Terraria server
  ];
  firewall.openUDPPorts = [];

  #--- Ad & Tracker Blocking (Steven Black hosts list)
  blocklist.enable = true;
  blocklist.extra = ["fakenews" "gambling" "porn"];

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
    "nixos-settings"
    "protonplus"
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
  suwayomi.enable = false;

  #--- Syncthing File Sync
  # Peer-to-peer sync, web UI at http://127.0.0.1:8384
  syncthing.enable = true;

  #--- Sunshine Game Streaming
  # Streams games to Moonlight clients on the LAN, web UI at https://localhost:47990
  sunshine.enable = false;

  #--- Flatpak, with Flatseal
  flatpak.enable = false;
}
