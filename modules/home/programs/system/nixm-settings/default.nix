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

  nixm-settings = pkgs.stdenvNoCC.mkDerivation {
    pname = "nixm-settings";
    version = "1.0";
    src = ./src;
    nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.gobject-introspection pkgs.makeWrapper];
    buildInputs = [pkgs.gtk4 pkgs.libadwaita];
    installPhase = ''
      runHook preInstall
      install -Dm644 -t $out/share/nixm-settings *.py descriptions.json
      makeWrapper ${python}/bin/python3 $out/bin/nixm-settings \
        --add-flags $out/share/nixm-settings/app.py \
        --set NIXM_SETTINGS_FLAKE ${lib.escapeShellArg machine.flakePath} \
        --set NIXM_SETTINGS_MACHINE ${lib.escapeShellArg machine.name} \
        --set NIXM_SETTINGS_USER ${lib.escapeShellArg user.name} \
        --set NIXM_SETTINGS_LIB ${pkgs.path}/lib \
        --prefix PATH : ${lib.makeBinPath [alejandra]}
      runHook postInstall
    '';
  };
in {
  home.packages = [nixm-settings];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#

  xdg.desktopEntries.nixm-settings = {
    name = "nixm Settings";
    genericName = "System Settings";
    comment = "Pick apps and system options, then rebuild";
    exec = "nixm-settings";
    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
    terminal = false;
    categories = ["Settings" "System"];
    settings.StartupWMClass = "dev.nixm.Settings";
  };
}
