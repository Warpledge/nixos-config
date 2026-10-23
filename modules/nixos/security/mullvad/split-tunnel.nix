#=====================================================================#
# MULLVAD SPLIT TUNNEL
#=====================================================================#
#- Routes chosen apps around the VPN. `mullvad-exclude` puts a process in
#- the `mullvad-exclusions` cgroup at launch and its children inherit it,
#- so wrapping a launcher covers every game it starts.
#-
#- Each wrapper shadows the real command in PATH, so desktop entries and
#- the shell both go through it; Steam is single-instance, so its wrapper
#- must own every entry point. Apps from home.packages get a home wrapper,
#- since the home profile comes before /run/current-system/sw/bin.
#-
#- Lockdown mode doesn't block excluded processes, so no allowlist is needed.
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
    claude-desktop = {
      home = true;
      enable = user.claudeDesktop.enable;
      bin = "${hm.claude-desktop.package}/bin/claude-desktop";
    };
    lm-studio = {
      home = true;
      enable = user.lmstudio.enable;
      bin = "${pkgs.lmstudio}/bin/lm-studio";
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
    protonplus = {
      home = true;
      enable = true; # in every user's gaming packages, no toggle
      bin = "${pkgs.protonplus}/bin/protonplus";
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
