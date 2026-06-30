#=====================================================================#
# WAYDROID ANDROID CONTAINER
#=====================================================================#
{
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  config = lib.mkMerge [
    {
      #--------------------------------------------------------------------#
      #-- Package Overlay: patch waydroid-net.sh to not read /etc/hosts
      #--------------------------------------------------------------------#
      # dnsmasq crashes with SIGABRT on large /etc/hosts (stevenblack blocklist)
      nixpkgs.overlays = [
        (final: prev: {
          waydroid = prev.waydroid.overrideAttrs (old: {
            postInstall =
              (old.postInstall or "")
              + ''
                substituteInPlace $out/lib/waydroid/data/scripts/waydroid-net.sh \
                  --replace '--dhcp-authoritative' '--dhcp-authoritative --no-hosts'
              '';
          });
        })
      ];
    }

    (lib.mkIf hostConfig.waydroid.enable {
      #--------------------------------------------------------------------#
      #-- Waydroid Package & Service
      #--------------------------------------------------------------------#
      virtualisation.waydroid.enable = true;

      #--------------------------------------------------------------------#
      #-- Kernel Modules
      #--------------------------------------------------------------------#
      boot.kernelModules = [
        "binder_linux"
        "ashmem_linux"
        "ip6table_filter"
        "ip6table_nat"
      ];

      #--------------------------------------------------------------------#
      #-- Kernel Parameters
      #--------------------------------------------------------------------#
      boot.kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1;
        "kernel.unprivileged_bpf_disabled" = 0;
        "kernel.bpf_stats_enabled" = 0;
      };

      #--------------------------------------------------------------------#
      #-- System Packages
      #--------------------------------------------------------------------#
      environment.systemPackages = with pkgs;
        [
          waydroid
          waydroid-helper
          lzip
        ]
        ++ lib.optionals hostConfig.waydroid.magisk [
          magisk
        ];

      #--------------------------------------------------------------------#
      #-- dnsmasq Lease File Ownership
      #--------------------------------------------------------------------#
      # dnsmasq runs as nobody but NixOS creates this file as root, causing dnsmasq to die on start
      systemd.tmpfiles.rules = [
        "f /var/lib/misc/dnsmasq.waydroid0.leases 0644 nobody nogroup -"
      ];

      #--------------------------------------------------------------------#
      #-- Firewall / NAT Rules
      #--------------------------------------------------------------------#
      networking.firewall.extraCommands = ''
        iptables -t nat -A POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE
      '';

      networking.nftables = lib.mkIf hostConfig.waydroid.nftables {
        enable = true;
      };

      #--------------------------------------------------------------------#
      #-- User Namespace Settings
      #--------------------------------------------------------------------#
      security.unprivilegedUsernsClone = true;
    })
  ];
}
