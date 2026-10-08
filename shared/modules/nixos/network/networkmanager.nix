#=====================================================================#
# NETWORKMANAGER (IWD, MAC RANDOMISATION, IPV6 PRIVACY)
#=====================================================================#
{
  pkgs,
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
  };

  #--------------------------------------------------------------------#
  #-- System Integration
  #--------------------------------------------------------------------#
  environment.systemPackages = [
    pkgs.networkmanagerapplet # NetworkManager GUI applet
  ];
  hardware.wirelessRegulatoryDatabase = true; # Wireless regulatory info
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = ["" "${pkgs.networkmanager}/bin/nm-online -q"]; # Don't wait for network
  systemd.network.config.networkConfig.IPv6PrivacyExtensions = "kernel"; # "kernel" leaves the sysctl value in place
}
