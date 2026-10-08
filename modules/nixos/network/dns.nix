#=====================================================================#
# DNS (SYSTEMD-RESOLVED)
#=====================================================================#
{lib, ...}: {
  #--------------------------------------------------------------------#
  #-- DNS Configuration (systemd-resolved)
  #--------------------------------------------------------------------#
  services.resolved = lib.mkDefault {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = "opportunistic"; # Encrypt DNS queries when possible
      LLMNR = "false"; # Unneeded name resolution; spoofable on shared networks
      # Empty assignment disables systemd-resolved's compiled-in fallbacks.
      # Without this a Mullvad resolver failure silently falls back to
      # Cloudflare/Google, bypassing the DNS content blocking.
      FallbackDNS = [""];
    };
  };
}
