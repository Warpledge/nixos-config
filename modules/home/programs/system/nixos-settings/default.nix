#=====================================================================#
# NIXM SETTINGS CONFIGURATION
#=====================================================================#
#- GTK4/libadwaita app for the settings files: pick apps and machine
#- options from menus, and Apply writes them, checks them with
#- lib/settings.nix and runs `nixm rebuild` (or `nixm boot`)
{
  pkgs,
  lib,
  inputs,
  machine,
  user,
  ...
}: let
  python = pkgs.python3.withPackages (ps: [ps.pygobject3]);
  alejandra = inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system};

  nixos-settings = pkgs.stdenvNoCC.mkDerivation {
    pname = "nixos-settings";
    version = "1.0";
    src = ./src;
    nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.gobject-introspection pkgs.makeWrapper];
    buildInputs = [pkgs.gtk4 pkgs.libadwaita];
    installPhase = ''
      runHook preInstall
      install -Dm644 -t $out/share/nixos-settings *.py descriptions.json
      makeWrapper ${python}/bin/python3 $out/bin/nixos-settings \
        --add-flags $out/share/nixos-settings/app.py \
        --set NIXOS_SETTINGS_FLAKE ${lib.escapeShellArg machine.flakePath} \
        --set NIXOS_SETTINGS_MACHINE ${lib.escapeShellArg machine.name} \
        --set NIXOS_SETTINGS_USER ${lib.escapeShellArg user.name} \
        --set NIXOS_SETTINGS_LIB ${pkgs.path}/lib \
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
    comment = "Pick apps and system options, then rebuild";
    exec = "nixos-settings";
    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
    terminal = false;
    categories = ["Settings" "System"];
    settings.StartupWMClass = "dev.nixosconfig.Settings";
  };
}
