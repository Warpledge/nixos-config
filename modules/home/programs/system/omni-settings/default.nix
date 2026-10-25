#=====================================================================#
# OMNI SETTINGS CONFIGURATION
#=====================================================================#
#- QML app (Quickshell) for the settings files, as a window and as DMS's
#- panel: pick apps and machine options, and Apply writes them, checks them with
#- lib/settings.nix and rebuilds through the root helper
#- (nixos/system/user/omni-settings-helper.nix), which also updates the
#- flake inputs and switches back to earlier versions
{
  pkgs,
  lib,
  inputs,
  machine,
  user,
  osConfig,
  ...
}: let
  alejandra = inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system};
  #--- The weekly nh clean job (nixos/nix/nh.nix), which the Overview's clean-up matches
  clean = osConfig.programs.nh.clean;
  #--- Proton builds steam.nix adds to Steam, listed on Proton Versions
  steam = osConfig.programs.steam;
  compatTools = lib.concatMapStringsSep ";" (p: "${lib.getName p} ${lib.getVersion p}") (
    lib.optionals steam.enable steam.extraCompatPackages
  );
  #--- The user's default text editor, which the Default Packages pages open modules in
  editor = ((import ../../../../../lib/default-apps.nix {inherit lib;}).forUser user).textEditor;
  #--- Mullvad's split tunnel (nixos/security/mullvad/split-tunnel.nix): the panel runs
  #--- the backend from DMS's process, so the backend routes itself around the VPN
  excluded = machine.mullvad.enable && lib.elem "omni-settings" machine.mullvad.splitTunnel;
  backendPath =
    if excluded
    then "libexec/omni-settings-backend"
    else "bin/omni-settings-backend";

  omni-settings = pkgs.stdenvNoCC.mkDerivation {
    pname = "omni-settings";
    version = "2.0";
    src = ./src;
    nativeBuildInputs = [pkgs.makeWrapper];
    installPhase = ''
      runHook preInstall
      share=$out/share/omni-settings
      install -Dm644 -t $share *.py descriptions.json
      # Python can't cache bytecode in the store, so each call would recompile
      ${pkgs.python3}/bin/python3 -m compileall -q --invalidation-mode unchecked-hash $share
      install -Dm644 -t $share/qml ${./qml}/*.qml
      substitute ${./qml/Config.qml.in} $share/qml/Config.qml \
        --subst-var-by backend $out/bin/omni-settings-backend \
        --subst-var-by editor ${lib.escapeShellArg (builtins.toJSON {inherit (editor) launch desktop;})}
      #--- DMS's engine finds the singletons only through a qmldir (plugin/)
      for f in $share/qml/[A-Z]*.qml; do
        n=$(basename $f .qml)
        grep -q '^pragma Singleton' $f && echo "singleton $n 1.0 $n.qml" || echo "$n 1.0 $n.qml"
      done > $share/qml/qmldir
      install -Dm644 -t $share/plugin ${./plugin}/plugin.json
      substitute ${./plugin}/OmniPanel.qml $share/plugin/OmniPanel.qml --subst-var-by qml $share/qml
      #--- Pick lists for Language & Input; only the names reach the closure
      tar -xJOf ${pkgs.glibc.src} --wildcards '*/localedata/SUPPORTED' \
        | sed -n 's|^\([^/ ]*\)/UTF-8.*|\1|p' | sort -u > $share/locales.txt
      sed -n '/^! layout$/,/^! /s/^  *\([^ ]*\)  *\(.*\)$/\1 \2/p' \
        ${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/evdev.lst > $share/layouts.txt
      find ${pkgs.kbd}/share/keymaps -name '*.map.gz' -printf '%f\n' \
        | sed 's/\.map\.gz$//' | sort -u > $share/keymaps.txt
      #--- The window; the same view runs in DMS's panel (plugin/)
      makeWrapper ${pkgs.quickshell}/bin/qs $out/bin/omni-settings \
        --add-flags "-p $share/qml/shell.qml"
      #--- The backend the QML calls, one process per command (src/api.py)
      makeWrapper ${pkgs.python3}/bin/python3 $out/${backendPath} \
        --add-flags $share/api.py \
        --set OMNI_SETTINGS_FLAKE ${lib.escapeShellArg machine.flakePath} \
        --set OMNI_SETTINGS_MACHINE ${lib.escapeShellArg machine.name} \
        --set OMNI_SETTINGS_USER ${lib.escapeShellArg user.name} \
        --set OMNI_SETTINGS_LIB ${pkgs.path}/lib \
        --set OMNI_SETTINGS_CLEAN_ARGS ${lib.escapeShellArg clean.extraArgs} \
        --set OMNI_SETTINGS_CLEAN_DATES ${lib.escapeShellArg (lib.optionalString clean.enable clean.dates)} \
        --set OMNI_SETTINGS_COMPAT_TOOLS ${lib.escapeShellArg compatTools} \
        --prefix PATH : ${lib.makeBinPath [alejandra pkgs.nix-search-tv]}
      ${lib.optionalString excluded ''
        # The split tunnel's own wrapper only covers `omni-settings` run from PATH
        cat > $out/bin/omni-settings-backend <<EOF
        #!${pkgs.runtimeShell}
        if [ -x /run/wrappers/bin/mullvad-exclude ] &&
          [[ \$(</proc/self/cgroup) != *":net_cls:/mullvad-exclusions"* ]]; then
          exec /run/wrappers/bin/mullvad-exclude $out/${backendPath} "\$@"
        fi
        exec $out/${backendPath} "\$@"
        EOF
        chmod +x $out/bin/omni-settings-backend
      ''}
      #--- The job service (src/jobs.py): pkexec and nix from the system, not the session
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/omni-settings-jobs \
        --add-flags $share/jobs.py \
        --set OMNI_SETTINGS_ICON ${./icon.svg} \
        --set OMNI_SETTINGS_FLAKE ${lib.escapeShellArg machine.flakePath} \
        --set OMNI_SETTINGS_MACHINE ${lib.escapeShellArg machine.name} \
        --set OMNI_SETTINGS_USER ${lib.escapeShellArg user.name} \
        --set OMNI_SETTINGS_LIB ${pkgs.path}/lib \
        --prefix PATH : ${lib.makeBinPath [alejandra]}:/run/wrappers/bin:/run/current-system/sw/bin
      runHook postInstall
    '';
  };
in {
  #--- Read by the Mullvad split tunnel (nixos/security/mullvad/split-tunnel.nix)
  options.omni-settings.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "The Omni Settings build in home.packages.";
  };

  config.omni-settings.package = omni-settings;

  config.home.packages = [omni-settings];

  #--------------------------------------------------------------------#
  #-- Job Service
  #--------------------------------------------------------------------#

  #--- Started on the first connection; it exits on its own once idle
  config.systemd.user.sockets.omni-settings-jobs = {
    Unit.Description = "Omni Settings job service socket";
    Socket = {
      ListenStream = "%t/omni-settings/jobs.sock";
      SocketMode = "0600";
      DirectoryMode = "0700";
    };
    Install.WantedBy = ["sockets.target"];
  };

  config.systemd.user.services.omni-settings-jobs = {
    Unit = {
      Description = "Omni Settings job service";
      # A rebuild it runs mustn't restart it mid-job; the new build starts next time
      X-SwitchMethod = "keep-old";
    };
    Service.ExecStart = "${omni-settings}/bin/omni-settings-jobs";
  };

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#

  config.xdg.desktopEntries.omni-settings = {
    name = "Omni Settings";
    genericName = "System Settings";
    comment = "Pick apps and system options, rebuild and update";
    exec = "omni-settings";
    icon = "${./icon.svg}";
    terminal = false;
    categories = ["Settings" "System"];
    settings.StartupWMClass = "org.quickshell";
  };
}
