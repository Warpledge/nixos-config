#=====================================================================#
# FACE AUTH (HOWDY)
#=====================================================================#
#- Face or password for sudo, polkit and the DMS lock screen. The login
#- screen keeps the password, which is what unlocks the GNOME keyring.
#- Run `sudo howdy add` after the rebuild; a photo can fool Howdy.
{
  config,
  lib,
  machine,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (p: [p.numpy p.opencv4]);

  #--- Omni Settings' Face Auth page: add and remove faces (root), and the camera view
  tools = pkgs.stdenvNoCC.mkDerivation {
    pname = "omni-face-auth";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [pkgs.makeWrapper];
    installPhase = ''
      runHook preInstall
      install -Dm644 ${./face-auth-tool.py} $out/share/omni-face-auth/tool.py
      install -Dm644 ${./face-auth-preview.py} $out/share/omni-face-auth/preview.py
      # -I: no PYTHONPATH, user site or current folder on the import path
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/omni-face-auth \
        --add-flags "-I $out/share/omni-face-auth/tool.py" \
        --set OMNI_FACE_HOWDY ${lib.getExe' config.services.howdy.package "howdy"}
      makeWrapper ${python}/bin/python3 $out/bin/omni-face-preview \
        --add-flags "-I $out/share/omni-face-auth/preview.py"
      mkdir -p $out/share/polkit-1/actions
      cat > $out/share/polkit-1/actions/dev.nixosconfig.faceauth.policy <<EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
        "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
      <policyconfig>
        <action id="dev.nixosconfig.faceauth">
          <description>Change your saved faces</description>
          <message>Omni Settings needs to confirm it's you to change your saved faces</message>
          <defaults>
            <allow_any>no</allow_any>
            <allow_inactive>no</allow_inactive>
            <allow_active>auth_self</allow_active>
          </defaults>
          <annotate key="org.freedesktop.policykit.exec.path">$out/bin/omni-face-auth</annotate>
        </action>
      </policyconfig>
      EOF
      runHook postInstall
    '';
  };
in {
  environment.systemPackages = [tools];

  #--------------------------------------------------------------------#
  #-- Kernel Modules
  #--------------------------------------------------------------------#
  #--- hardening/kernel.nix loads v4l2loopback at boot, which Howdy's assertion
  #--- rejects. OBS's virtual camera now needs a manual modprobe.
  boot.kernelModules.v4l2loopback = lib.mkForce false;

  #--------------------------------------------------------------------#
  #-- Howdy
  #--------------------------------------------------------------------#
  services.howdy = {
    enable = true;
    control = "sufficient";
    settings.video =
      {
        dark_threshold = machine.faceAuth.darkThreshold;
        #--- 320 shrinks frames, so faces must be very close
        max_height = 480;
        timeout = 6;
      }
      // lib.optionalAttrs (machine.faceAuth.device != null) {
        device_path = machine.faceAuth.device;
      };
  };

  #--- Some IR cameras need `sudo linux-enable-ir-emitter configure --no-gui` once
  services.linux-enable-ir-emitter.enable = true;

  #--------------------------------------------------------------------#
  #-- PAM Services
  #--------------------------------------------------------------------#
  #--- On by default for every service; only the ones below opt in
  security.pam.howdy.enable = false;

  security.pam.services = {
    sudo.howdy.enable = true;
    polkit-1.howdy.enable = true;
    #--- DMS's lock screen uses this stack when /etc/pam.d/dankshell exists
    dankshell.howdy.enable = true;
    #--- DMS starts PAM on Enter, so password first: a typed one skips the scan
    #--- and an empty Enter fails through to Howdy
    dankshell.rules.auth.howdy.order =
      config.security.pam.services.dankshell.rules.auth.unix.order + 10;
  };

  #--------------------------------------------------------------------#
  #-- Polkit Sandbox
  #--------------------------------------------------------------------#
  #--- polkit's helper is denied all devices upstream; Howdy needs the camera
  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;
    DeviceAllow = ["char-video4linux rw"];
  };
}
