#=====================================================================#
# NIXOS SETTINGS CONFIGURATION
#=====================================================================#
#- GTK4/libadwaita app for the settings files: pick apps and machine
#- options from menus, and Apply writes them, checks them with
#- lib/settings.nix and rebuilds through the root helper
#- (nixos/system/user/nixos-settings-helper.nix), which also updates the
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
  python = pkgs.python3.withPackages (ps: [ps.pygobject3]);
  alejandra = inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system};
  #--- The weekly nh clean job (nixos/nix/nh.nix), which the Overview's clean-up matches
  clean = osConfig.programs.nh.clean;

  nixos-settings = pkgs.stdenvNoCC.mkDerivation {
    pname = "nixos-settings";
    version = "2.0";
    src = ./src;
    nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.gobject-introspection pkgs.makeWrapper];
    buildInputs = [pkgs.gtk4 pkgs.libadwaita];
    installPhase = ''
      runHook preInstall
      share=$out/share/nixos-settings
      install -Dm644 -t $share *.py descriptions.json
      #--- Pick lists for Language & Keyboard; only the names reach the closure
      tar -xJOf ${pkgs.glibc.src} --wildcards '*/localedata/SUPPORTED' \
        | sed -n 's|^\([^/ ]*\)/UTF-8.*|\1|p' | sort -u > $share/locales.txt
      sed -n '/^! layout$/,/^! /s/^  *\([^ ]*\)  *\(.*\)$/\1 \2/p' \
        ${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/evdev.lst > $share/layouts.txt
      find ${pkgs.kbd}/share/keymaps -name '*.map.gz' -printf '%f\n' \
        | sed 's/\.map\.gz$//' | sort -u > $share/keymaps.txt
      makeWrapper ${python}/bin/python3 $out/bin/nixos-settings \
        --add-flags $share/app.py \
        --set NIXOS_SETTINGS_FLAKE ${lib.escapeShellArg machine.flakePath} \
        --set NIXOS_SETTINGS_MACHINE ${lib.escapeShellArg machine.name} \
        --set NIXOS_SETTINGS_USER ${lib.escapeShellArg user.name} \
        --set NIXOS_SETTINGS_LIB ${pkgs.path}/lib \
        --set NIXOS_SETTINGS_CLEAN_ARGS ${lib.escapeShellArg clean.extraArgs} \
        --set NIXOS_SETTINGS_CLEAN_DATES ${lib.escapeShellArg (lib.optionalString clean.enable clean.dates)} \
        --prefix PATH : ${lib.makeBinPath [alejandra]}
      runHook postInstall
    '';
  };
in {
  home.packages = [nixos-settings];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#

  xdg.desktopEntries.nixos-settings = {
    name = "NixOS Settings";
    genericName = "System Settings";
    comment = "Pick apps and system options, rebuild and update";
    exec = "nixos-settings";
    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
    terminal = false;
    categories = ["Settings" "System"];
    settings.StartupWMClass = "dev.nixosconfig.Settings";
  };
}
