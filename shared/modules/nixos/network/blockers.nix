#=====================================================================#
# HOST BLOCKLISTS AND FILTERING
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Steven Black Host Blocklist
  #--------------------------------------------------------------------#
  networking = {
    stevenblack = {
      enable = true;
      #--- Drops the list's own `localhost` lines; NixOS already writes
      #--- 127.0.0.1/::1, and its macOS-only `fe80::1%lo0 localhost` breaks
      #--- apps dialing localhost (Tsunagu's sandbox never became ready)
      package = pkgs.stevenblack-blocklist.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            sed -i -E '/^[^#[:space:]]+[[:space:]]+localhost$/d' $out/hosts $ads/hosts
          '';
      });
      block = [
        "fakenews"
        "gambling"
      ];
    };
  };
}
