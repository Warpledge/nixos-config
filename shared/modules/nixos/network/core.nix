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
    useDHCP = false;
    useNetworkd = true;
    usePredictableInterfaceNames = true;
    networkmanager = {
      enable = true;
      plugins = [];
      dns = "systemd-resolved";
      unmanaged = [
        "interface-name:docker*" # Don't manage Docker interfaces
        "interface-name:virbr*" # Don't manage libvirt bridges
        "interface-name:vboxnet*" # Don't manage VirtualBox interfaces
      ];
      wifi = {
        backend = "iwd"; # iwd backend (more secure than wpa_supplicant)
        macAddress = "random";
        powersave = true;
        scanRandMacAddress = true;
      };
      ethernet.macAddress = "stable";
      connectionConfig = {
        "ipv6.ip6-privacy" = 2; # Enable IPv6 privacy extensions
      };
    };

    #--------------------------------------------------------------------#
    #-- Firewall Configuration
    #--------------------------------------------------------------------#
    firewall = {
      enable = true;
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
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
    openFirewall = false;
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
  systemd.network.config.networkConfig.IPv6PrivacyExtensions = "kernel"; # "kernel" leaves the sysctl value in place

  #--------------------------------------------------------------------#
  #-- DNS Configuration (systemd-resolved)
  #--------------------------------------------------------------------#
  services.resolved = lib.mkDefault {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = "opportunistic"; # Encrypt DNS queries when possible
      # Empty assignment disables systemd-resolved's compiled-in fallbacks.
      # Without this a Mullvad resolver failure silently falls back to
      # Cloudflare/Google, bypassing the DNS content blocking.
      FallbackDNS = [""];
    };
  };

  #--- Default system nameservers (can be overridden by AdGuard Home)
  networking.nameservers = lib.mkDefault [];
}
