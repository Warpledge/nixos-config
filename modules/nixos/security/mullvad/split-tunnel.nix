#=====================================================================#
# MULLVAD SPLIT TUNNEL
#=====================================================================#
#- Routes chosen apps around the VPN, permanently.
#-
#- Unlike Android, Mullvad on Linux keeps no per-app list: exclusion is
#- decided at launch by `mullvad-exclude`, which puts the process in the
#- `mullvad-exclusions` net_cls cgroup. Membership is inherited on fork
#- and survives reparenting and systemd-run scopes, so wrapping a
#- launcher also covers every game it spawns.
#-
#- Each name here shadows the real command with a higher-priority
#- wrapper, so the desktop entry (Exec=steam, resolved via PATH) and the
#- shell both go through it. Steam is single-instance: an unwrapped
#- instance started first would silently claim later launches, which is
#- why the wrapper has to own every entry point.
#-
#- The home profile sits earlier in PATH than /run/current-system/sw/bin,
#- so a system wrapper for a home-manager package is shadowed and never
#- runs. Anything installed via home.packages is wrapped there instead.
#-
#- Mullvad's lockdown mode does NOT block excluded processes on Linux,
#- so no allowlist is needed alongside this.
{
  config,
  lib,
  pkgs,
  machine,
  anyUser,
  ...
}: let
  wanted = machine.mullvad.splitTunnel;

  #--- Command name -> the real binary it shadows. `home` picks the profile
  #--- the wrapper goes in; `enable` follows the app's own toggle so a shared
  #--- splitTunnel list cannot pull an app onto a host that does not install it.
  #--- Home entries follow `user`'s toggles and home; steam is system-wide.
  targetsFor = user: let
    hm = config.home-manager.users.${user.name};
  in {
    steam = {
      home = false;
      enable = anyUser.gaming.steam;
      bin = "${config.programs.steam.package}/bin/steam";
    };
    heroic = {
      home = true;
      enable = user.gaming.heroic;
      bin = "${pkgs.heroic}/bin/heroic";
    };
    prismlauncher = {
      home = true;
      enable = user.gaming.prismlauncher;
      bin = "${pkgs.prismlauncher}/bin/prismlauncher";
    };
    claude = {
      home = true;
      enable = user.claude.enable;
      # The package programs.claude-code installs, incl. any plugin wrapper
      bin = "${hm.programs.claude-code.finalPackage}/bin/claude";
    };
    opencode = {
      home = true;
      enable = user.opencode.enable;
      bin = "${pkgs.opencode}/bin/opencode";
    };
    freetube = {
      home = true;
      enable = user.media.freetube;
      bin = "${pkgs.freetube}/bin/freetube";
    };
    spotify = {
      home = true;
      enable = user.media.spotify;
      # spicetify-nix builds its own Spotify; pkgs.spotify is the wrong one
      bin = "${hm.programs.spicetify.spicedSpotify}/bin/spotify";
    };
    ferdium = {
      home = true;
      enable = user.browsers.ferdium;
      # RateYourMusic and similar sites reject Mullvad exit IPs
      bin = "${pkgs.ferdium}/bin/ferdium";
    };
    nixos-settings = {
      home = true;
      enable = true; # imported for every user, no toggle
      bin = "${hm.nixos-settings.package}/bin/nixos-settings";
    };
  };

  #--- The system entries are the same in every user's table
  systemTargets = targetsFor machine.users.${machine.mainUser};

  unknown = lib.subtractLists (lib.attrNames systemTargets) wanted;
  active = targets: lib.filter (n: targets ? ${n} && targets.${n}.enable) wanted;

  #--- Falls back to running unwrapped if the setuid helper is absent,
  #--- so disabling Mullvad cannot leave an unlaunchable app behind.
  wrapperFor = targets: name:
    lib.hiPrio (pkgs.writeShellScriptBin name ''
      real=${lib.escapeShellArg targets.${name}.bin}
      # Steam sets no_new_privs on the processes it launches, which neuters the
      # setuid helper; children inherit the cgroup anyway, so skip the second hop.
      if [ -x /run/wrappers/bin/mullvad-exclude ] &&
        [[ $(</proc/self/cgroup) != *":net_cls:/mullvad-exclusions"* ]]; then
        exec /run/wrappers/bin/mullvad-exclude "$real" "$@"
      fi
      exec "$real" "$@"
    '');
  wrappers = targets: home: map (wrapperFor targets) (lib.filter (n: targets.${n}.home == home) (active targets));
in {
  config = lib.mkIf (wanted != []) {
    assertions = [
      {
        assertion = unknown == [];
        message = "mullvad.splitTunnel: no wrapper defined for ${lib.concatStringsSep ", " unknown}. Add it to `targetsFor` in security/mullvad/split-tunnel.nix.";
      }
    ];

    environment.systemPackages = wrappers systemTargets false;
    home-manager.users = lib.mapAttrs (_: user: {home.packages = wrappers (targetsFor user) true;}) machine.users;
  };
}
