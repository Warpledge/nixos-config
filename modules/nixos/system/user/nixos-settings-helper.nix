#=====================================================================#
# NIXOS SETTINGS HELPER
#=====================================================================#
#- Lets a user who isn't an admin apply their own app settings from NixOS
#- Settings: pkexec runs nixos-settings-apply as root after that user types
#- their own password. The script is src/helper.py beside the app.
{
  config,
  pkgs,
  lib,
  inputs,
  machine,
  ...
}: let
  alejandra = inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system};

  helper = pkgs.stdenvNoCC.mkDerivation {
    pname = "nixos-settings-apply";
    version = "1.0";
    src = ../../../home/programs/system/nixos-settings/src;
    nativeBuildInputs = [pkgs.makeWrapper];
    installPhase = ''
      runHook preInstall
      install -Dm644 -t $out/share/nixos-settings-apply *.py
      # -I: no PYTHONPATH, user site or current folder on the import path
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/nixos-settings-apply \
        --add-flags "-I $out/share/nixos-settings-apply/helper.py" \
        --set NIXOS_SETTINGS_FLAKE ${lib.escapeShellArg machine.flakePath} \
        --set NIXOS_SETTINGS_MACHINE ${lib.escapeShellArg machine.name} \
        --set NIXOS_SETTINGS_LIB ${pkgs.path}/lib \
        --set PATH ${lib.makeBinPath [alejandra config.nix.package pkgs.git]}:/run/current-system/sw/bin
      mkdir -p $out/share/polkit-1/actions
      cat > $out/share/polkit-1/actions/dev.nixosconfig.settings.apply.policy <<EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
        "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
      <policyconfig>
        <action id="dev.nixosconfig.settings.apply">
          <description>Apply your own app settings</description>
          <message>NixOS Settings needs your password to apply your app settings</message>
          <defaults>
            <allow_any>no</allow_any>
            <allow_inactive>no</allow_inactive>
            <allow_active>auth_self</allow_active>
          </defaults>
          <annotate key="org.freedesktop.policykit.exec.path">$out/bin/nixos-settings-apply</annotate>
        </action>
      </policyconfig>
      EOF
      runHook postInstall
    '';
  };
in {
  security.polkit.enable = true;
  environment.systemPackages = [helper];
}
