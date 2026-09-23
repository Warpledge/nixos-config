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
    protectKernelImage = true;
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
      enableGnomeKeyring = true;
    };
    login = {}; # Login service
    gdm = {
      enableGnomeKeyring = true;
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
  security.sudo.enable = true;

  #--------------------------------------------------------------------#
  #-- Services Configuration
  #--------------------------------------------------------------------#
  services = {};

  #--------------------------------------------------------------------#
  #-- GNOME Keyring
  #--------------------------------------------------------------------#
  services.gnome.gcr-ssh-agent.enable = false; # disabled: conflicts with gpg-agent's SSH support (cyclic gpg-agent-ssh.socket dependency)
  programs = {
    seahorse.enable = true; # GUI for managing keyring credentials
    gnupg.agent = {
      enable = true;
      enableSSHSupport = false; # owned by home-manager's services.gpg-agent to avoid a cyclic gpg-agent-ssh.socket dependency
    };
    #--- Disable SSH UseRoaming vulnerability
    ssh.extraConfig = ''
      Host *
        UseRoaming no
    '';
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
  services.dbus.implementation = "broker";

  #--------------------------------------------------------------------#
  #-- Bootloader Security
  #--------------------------------------------------------------------#
  boot.loader.systemd-boot.editor = lib.mkDefault false; # Disable bootloader editor
}
