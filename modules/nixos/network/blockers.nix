#=====================================================================#
# HOST BLOCKLISTS AND FILTERING
#=====================================================================#
{
  config,
  lib,
  pkgs,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Steven Black Host Blocklist
  #--------------------------------------------------------------------#
  networking = {
    stevenblack = {
      enable = true;
      #--- Drops the list's own `localhost` lines; NixOS already writes
      #--- 127.0.0.1/::1, and its macOS-only `fe80::1%lo0 localhost` breaks
      #--- apps dialing localhost
      package = pkgs.stevenblack-blocklist.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            sed -i -E '/^[^#[:space:]]+[[:space:]]+localhost$/d' $out/hosts $ads/hosts
          '';
      });
      block = machine.blocklist.extra; # The machine's settings.nix
      whitelist = machine.blocklist.allow;
    };
  };

  #--------------------------------------------------------------------#
  #-- List Paths for Omni Settings
  #--------------------------------------------------------------------#
  #--- Each list's own hosts file, for Network's "Was this blocked?" lookup
  environment.etc."omni-settings/blocklists.json".text = builtins.toJSON (lib.genAttrs
    (["ads"] ++ config.networking.stevenblack.block)
    (name: "${lib.getOutput name config.networking.stevenblack.package}/hosts"));
}
