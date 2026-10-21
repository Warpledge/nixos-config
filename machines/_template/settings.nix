#=====================================================================#
# MACHINE SETTINGS (TEMPLATE)
#=====================================================================#
#- A new computer gets a copy of this folder at machines/<name>/. Running
#- ./setup.sh makes the copy and fills in the blanks; <name> is what the
#- config calls the machine (`nixm rebuild` builds it).
#-
#- This file also lists every machine setting there is. Anything your copy
#- leaves out is off (false), empty or null. Apps are chosen per person, in
#- users/<username>/settings.nix, not here.
{
  #--------------------------------------------------------------------#
  #-- Users
  #--------------------------------------------------------------------#
  #--- Who can log in here. Each name needs a users/<name>/settings.nix
  #--- (./setup.sh add-user makes one). Settings inside the braces change
  #--- that person's file on this machine only:
  #---   alice = {gaming.steam = false;};
  users = {
    # alice = {};
  };

  #--- Who owns this config: the repo sits in their home folder, Syncthing
  #--- runs as them and the login screen uses their theme. Must be an admin.
  #--- null works when only one user is listed.
  mainUser = null;

  #--------------------------------------------------------------------#
  #-- System
  #--------------------------------------------------------------------#
  #--- The NixOS release this machine was installed with: copy the
  #--- system.stateVersion line from /etc/nixos/configuration.nix, in
  #--- quotes, and never change it afterwards
  stateVersion = null;

  #--- Network name; null uses the folder name
  hostName = null;

  #--- Where this repo is cloned; null means /etc/nixos-config, which every
  #--- admin can edit (setup.sh moves it there)
  flakePath = null;

  #--- Window Manager Selection, for everyone on this machine
  # Options: "niri"
  windowManager = "niri";

  #--- Kernel Selection
  # Options: "zen" | "latest" | "xanmod" | "cachyos"
  # "cachyos" compiles on this computer, which takes a long time (its binary
  # cache is off in nix/substituters.nix), and needs an x86-64-v3 CPU (AVX2)
  kernel = "zen";

  #--- Mouse Cursor
  # Options: "bibata" (Bibata-Modern-Ice) | "catppuccin" (Catppuccin Mocha Mauve)
  cursor = "bibata";
  cursorSize = 24; # Pixels: 24, 32, 48 or 64

  #--- Graphics Drivers
  # "amd", "intel" or "nvidia" for one graphics chip. A laptop with an AMD or
  # Intel chip plus an NVIDIA one: "amd+nvidia" or "intel+nvidia", with both
  # bus IDs (setup.sh reads them). null installs nothing: for a machine whose
  # own hardware/ files set up the drivers.
  gpu.type = null;
  gpu.nvidiaLegacy = false; # GTX 900/1000 cards: the 580 driver, closed module
  gpu.nvidiaBusId = ""; # Hybrid laptops only, e.g. "PCI:1:0:0"
  gpu.integratedBusId = ""; # Hybrid laptops only: the AMD or Intel chip

  #--------------------------------------------------------------------#
  #-- Language & Keyboard
  #--------------------------------------------------------------------#
  #--- setup.sh copies these from the choices made in the NixOS installer
  timeZone = "UTC"; # e.g. "Europe/Berlin"; `timedatectl list-timezones`
  locale = "en_US.UTF-8";
  keyboardLayout = "us"; # Desktop layout, e.g. "gb", "de", "fr"
  # Same layout for the text console and the disk password prompt; a few
  # are named differently there ("uk" for "gb")
  consoleKeyMap = "us";

  #--- Caps Lock: Escape when tapped, Ctrl when held (keyd)
  capsLockRemap = false;

  #--------------------------------------------------------------------#
  #-- Devices
  #--------------------------------------------------------------------#
  #--- Bluetooth, powered on at boot
  bluetooth.enable = false;

  #--- Printing (CUPS); Avahi finds network printers and opens UDP 5353
  printing.enable = false;

  #--------------------------------------------------------------------#
  #-- Network & Firewall
  #--------------------------------------------------------------------#
  #--- Open Ports
  # Ports other devices may connect to, e.g. a game server. SSH, Syncthing,
  # Sunshine, Steam and printing open their own while they're on.
  firewall.openTCPPorts = [];
  firewall.openUDPPorts = [];

  #--- Ad & Tracker Blocking
  # Steven Black's hosts list, for every app on this computer
  blocklist.enable = false;
  # Extra categories to block. Known names: fakenews, gambling, porn, social
  blocklist.extra = [];

  #--------------------------------------------------------------------#
  #-- Services
  #--------------------------------------------------------------------#
  #--- Mullvad VPN (needs a Mullvad account)
  mullvad.enable = false;
  # Apps always routed around the VPN (see nixos/security/mullvad/). Known
  # names: steam, heroic, prismlauncher, opencode, claude, spotify, freetube,
  # ferdium, nixos-settings, protonplus
  mullvad.splitTunnel = [];

  #--- SSH Server
  # Key-only openssh + fail2ban. Add a public key to a user's
  # ssh.authorizedKeys before enabling, or there is no way in.
  ssh.enable = false;

  #--- ClamAV Antivirus
  # Enable ClamAV daemon, freshclam auto-updater, and ClamTK GUI
  clamav.enable = false;

  #--- Docker Containerization
  # Docker and Docker Compose; admins join the docker group
  docker.enable = false;

  #--- Suwayomi Manga Server
  # Local manga reader, web UI at http://localhost:4567. Its launcher opens
  # in Helium (browsers.helium).
  suwayomi.enable = false;

  #--- Syncthing File Sync
  # Peer-to-peer sync as the main user, web UI at http://127.0.0.1:8384
  syncthing.enable = false;

  #--- Sunshine Game Streaming
  # Streams games to Moonlight clients on the LAN, web UI at https://localhost:47990
  sunshine.enable = false;

  #--- Flatpak
  # Sandboxed apps from Flathub or a downloaded bundle, with Flatseal to
  # change what each may reach
  flatpak.enable = false;
}
