#=====================================================================#
# SECURITY CORE CONFIGURATION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Kernel Security Hardening
  #--------------------------------------------------------------------#
  security = {
    forcePageTableIsolation = true; # Mitigate Meltdown CPU vulnerability
    protectKernelImage = true; # Prevent kernel image modification
    apparmor = {
      enable = true; # Mandatory access control framework
      killUnconfinedConfinables = false; # Don't kill unconfined processes
    };
  };

  #--------------------------------------------------------------------#
  #-- Systemd Hardening
  #--------------------------------------------------------------------#
  systemd = {
    coredump.settings.Coredump = {
      Storage = "none"; # Disable core dumps for security
      ProcessSizeMax = 0; # Prevent large process dumps
    };
  };

  #--------------------------------------------------------------------#
  #-- PAM Services Configuration
  #--------------------------------------------------------------------#
  security.pam.services = {
    greetd = {
      enableGnomeKeyring = true; # Enable keyring for greeter
    };
    login = {}; # Login service
    gdm = {
      enableGnomeKeyring = true; # Enable keyring for GDM login
    };
    sddm = {}; # Simple Desktop Display Manager
    hyprlock = {}; # Hyprland screen locker
    swaylock = {}; # Sway screen locker
    sudo = {}; # Sudo authentication
    su = {}; # Switch user authentication
  };

  #--------------------------------------------------------------------#
  #-- Sudo Configuration
  #--------------------------------------------------------------------#
  security.sudo.enable = true; # Enable sudo command

  #--------------------------------------------------------------------#
  #-- Services Configuration
  #--------------------------------------------------------------------#
  services = {};

  #--------------------------------------------------------------------#
  #-- GNOME Keyring
  #--------------------------------------------------------------------#
  services.gnome.gnome-keyring.enable = true; # GNOME Keyring for password storage
  programs.seahorse.enable = true; # GUI for managing keyring credentials
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  #--------------------------------------------------------------------#
  #-- Fail2ban Intrusion Prevention
  #--------------------------------------------------------------------#
  services.fail2ban = {
    enable = true; # Enable intrusion prevention
    ignoreIP = [
      "127.0.0.1" # Localhost
      "127.0.0.1/8" # Localhost subnet
      "::1" # IPv6 localhost
    ];
    bantime = "12h"; # Ban duration
    bantime-increment = {
      enable = true; # Enable escalating ban times
      multipliers = "1 2 4 8 16 32 64"; # Exponential multipliers
      maxtime = "168h"; # 1 week maximum ban
    };
    jails = {
      ssh = ''
        enabled = false
        port = 22
      '';
    };
    maxretry = 3; # Ban after 3 failed attempts
  };

  #--------------------------------------------------------------------#
  #-- Intrusion Detection System (IDS) Tools
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    vulnix # Vulnerability scanner for NixOS
    lynis # Security auditing tool
  ];

  #--------------------------------------------------------------------#
  #-- Nix Configuration
  #--------------------------------------------------------------------#
  nix.settings.allowed-users = lib.mkForce ["@wheel"]; # Only wheel users can use nix

  #--------------------------------------------------------------------#
  #-- DBus Configuration
  #--------------------------------------------------------------------#
  services.dbus.implementation = "broker"; # Use dbus-broker

  #--------------------------------------------------------------------#
  #-- SSH Client Hardening
  #--------------------------------------------------------------------#
  programs.ssh = {
    #--- Disable SSH UseRoaming vulnerability
    extraConfig = ''
      Host *
        UseRoaming no
    '';
  };

  #--------------------------------------------------------------------#
  #-- Bootloader Security
  #--------------------------------------------------------------------#
  boot.loader.systemd-boot.editor = lib.mkDefault false; # Disable bootloader editor
}
