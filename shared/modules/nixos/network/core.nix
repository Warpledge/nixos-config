#=====================================================================#
# NETWORKING CONFIGURATION (NETWORKMANAGER, FIREWALL, SSH)
#=====================================================================#
{
  pkgs,
  lib,
  hostname,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- NetworkManager Configuration
  #--------------------------------------------------------------------#
  networking = {
    hostName = "${hostname}";
    useDHCP = false; # Don't use DHCP globally
    useNetworkd = true; # Use systemd-networkd
    usePredictableInterfaceNames = true; # Use stable interface names
    networkmanager = {
      enable = true; # Enable NetworkManager
      plugins = [];
      dns = "systemd-resolved"; # Use systemd-resolved for DNS
      unmanaged = [
        "interface-name:docker*" # Don't manage Docker interfaces
        "interface-name:virbr*" # Don't manage libvirt bridges
        "interface-name:vboxnet*" # Don't manage VirtualBox interfaces
        "interface-name:waydroid*" # Don't manage Waydroid interfaces
      ];
      wifi = {
        backend = "iwd"; # iwd backend (more secure than wpa_supplicant)
        macAddress = "random"; # Randomize MAC address
        powersave = true; # Enable WiFi power saving
        scanRandMacAddress = true; # Randomize MAC during scans
      };
      ethernet.macAddress = "stable"; # Keep stable Ethernet MAC
      connectionConfig = {
        "ipv6.ip6-privacy" = 2; # Enable IPv6 privacy extensions
      };
    };

    #--------------------------------------------------------------------#
    #-- Firewall Configuration
    #--------------------------------------------------------------------#
    firewall = {
      enable = true; # Enable UFW-style firewall
      allowedTCPPorts = [
        22 # SSH (disabled in services.openssh, but port reserved)
        80 # HTTP
        443 # HTTPS
        25566 # Minecraft server
        7777 # Terraria server
        5555 # ADB port
      ];
      allowedUDPPorts = [
        27000
        27001
        27002
        27003
        27004
        27005
        27006
        27007
        27008
        27009
        27015
        27031
        27032
        27033
        27034
        27035
        27036
        4380 # Steam networking
      ];
      #--- Ephemeral ports (49152-65535) for P2P game traffic handled by NAT
    };
  };

  #--------------------------------------------------------------------#
  #-- SSH Hardening
  #--------------------------------------------------------------------#
  services.openssh = {
    enable = false; # SSH disabled (GitHub uses HTTPS)
    settings = {
      PasswordAuthentication = false; # No password auth
      PermitRootLogin = "no"; # No root login
      KbdInteractiveAuthentication = false; # No interactive auth
      X11Forwarding = false; # No X11 forwarding
    };
    openFirewall = false; # Don't open firewall for SSH
  };

  #--------------------------------------------------------------------#
  #-- System Integration
  #--------------------------------------------------------------------#
  boot.kernelModules = ["af_packet"]; # Packet capturing/injection support
  environment.systemPackages = with pkgs; [
    networkmanagerapplet # NetworkManager GUI applet
    mtr # Network diagnostics tool
    tcpdump # Packet analyzer
    traceroute # Network trace tool
  ];
  hardware.wirelessRegulatoryDatabase = true; # Wireless regulatory info
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = ["" "${pkgs.networkmanager}/bin/nm-online -q"]; # Don't wait for network
  systemd.network.config.networkConfig.IPv6PrivacyExtensions = "kernel"; # IPv6 privacy extensions

  #--------------------------------------------------------------------#
  #-- DNS Configuration (systemd-resolved)
  #--------------------------------------------------------------------#
  services.resolved = lib.mkDefault {
    enable = true; # Enable systemd-resolved for DNS
    settings.Resolve = {
      DNSOverTLS = "opportunistic"; # Encrypt DNS queries when possible
      FallbackDNS = [
        "1.1.1.1#cloudflare-dns.com" # Cloudflare DNS (fallback)
        "8.8.8.8#dns.google" # Google DNS (fallback)
        "8.8.4.4#dns.google" # Google DNS secondary (fallback)
      ];
    };
  };

  #--- Default system nameservers (can be overridden by AdGuard Home)
  networking.nameservers = lib.mkDefault [];
}
