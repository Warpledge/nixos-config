#=====================================================================#
# OMNI SETTINGS HELPER
#=====================================================================#
#- Every rebuild Omni Settings starts: pkexec runs omni-settings-apply as
#- root after the user types their own password. Anyone may apply their own
#- app settings; rebuilding as-is or switching versions is for admins. The
#- script is src/helper.py beside the app.
{
  config,
  pkgs,
  lib,
  machine,
  ...
}: let
  inherit (pkgs) alejandra;

  helper = pkgs.stdenvNoCC.mkDerivation {
    pname = "omni-settings-apply";
    version = "1.0";
    src = ../../../home/programs/system/omni-settings/src;
    nativeBuildInputs = [pkgs.makeWrapper];
    installPhase = ''
      runHook preInstall
      install -Dm644 -t $out/share/omni-settings-apply *.py
      # -I: no PYTHONPATH, user site or current folder on the import path
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/omni-settings-apply \
        --add-flags "-I $out/share/omni-settings-apply/helper.py" \
        --set OMNI_SETTINGS_FLAKE ${lib.escapeShellArg machine.flakePath} \
        --set OMNI_SETTINGS_MACHINE ${lib.escapeShellArg machine.name} \
        --set OMNI_SETTINGS_LIB ${pkgs.path}/lib \
        --set OMNI_SETTINGS_CLEAN_ARGS ${lib.escapeShellArg config.programs.nh.clean.extraArgs} \
        --set PATH ${lib.makeBinPath [alejandra config.nix.package pkgs.git]}:/run/current-system/sw/bin
      mkdir -p $out/share/polkit-1/actions
      cat > $out/share/polkit-1/actions/dev.nixosconfig.settings.apply.policy <<EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
        "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
      <policyconfig>
        <action id="dev.nixosconfig.settings.apply">
          <description>Apply settings and rebuild the system</description>
          <message>Omni Settings needs your password to change the system</message>
          <defaults>
            <allow_any>no</allow_any>
            <allow_inactive>no</allow_inactive>
            <allow_active>auth_self_keep</allow_active>
          </defaults>
          <annotate key="org.freedesktop.policykit.exec.path">$out/bin/omni-settings-apply</annotate>
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
