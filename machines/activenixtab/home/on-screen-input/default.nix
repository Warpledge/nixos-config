#=====================================================================#
# ON-SCREEN KEYBOARD AND TOUCHPAD
#=====================================================================#
#- For using the Z13 without its folio: wvkbd as the keyboard, and a touchpad
#- panel that drives a virtual touchpad. Each has a DMS bar button; a swipe
#- up from the bottom edge (wm/touch-gestures.py) toggles the keyboard.
{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = "${config.xdg.configHome}/wvkbd/colors.sh";

  #--- The touchpad sits right of the keyboard, at its height (logical px)
  padWidth = 480;
  height = 300;

  #--- The desktop layout (F keys, number row, Tab, Ctrl…), plus a right margin
  wvkbd = pkgs.wvkbd.overrideAttrs (old: {
    makeFlags = (old.makeFlags or []) ++ ["LAYOUT=deskintl"];
    patches = (old.patches or []) ++ [./wvkbd-margin.patch ./wvkbd-uinput.patch];
  });

  keyboard = pkgs.writeShellScript "wvkbd-start" ''
    WVKBD_COLORS=""
    [ -r "${colors}" ] && . "${colors}"
    export WVKBD_MARGIN_RIGHT=${toString padWidth}
    # Type through uinput, so niri's binds, keyd and polkit prompts see the keys
    export WVKBD_UINPUT=1
    # shellcheck disable=SC2086 # one flag per word
    exec ${wvkbd}/bin/wvkbd-deskintl --hidden -H ${toString height} -L ${toString height} \
      --fn "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.popups}" \
      $WVKBD_COLORS
  '';

  osk-toggle = pkgs.writeShellScriptBin "osk-toggle" ''
    pkill --signal RTMIN -x wvkbd-deskintl
  '';

  touchpad = pkgs.stdenv.mkDerivation {
    pname = "on-screen-touchpad";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.gobject-introspection];
    buildInputs = [pkgs.gtk4 pkgs.gtk4-layer-shell];
    installPhase = ''
      install -Dm644 ${./touchpad.py} $out/share/on-screen-touchpad.py
      mkdir -p $out/bin
      makeWrapper ${pkgs.python3.withPackages (p: [p.evdev p.pygobject3])}/bin/python3 \
        $out/bin/on-screen-touchpad --add-flags $out/share/on-screen-touchpad.py
    '';
    # gtk4-layer-shell has to load before libwayland
    preFixup = ''
      gappsWrapperArgs+=(--set LD_PRELOAD ${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so
        --set TOUCHPAD_SIZE ${toString padWidth}x${toString height})
    '';
    postFixup = ''
      wrapGApp $out/bin/on-screen-touchpad
    '';
    dontWrapGApps = true;
  };

  touchpad-toggle = pkgs.writeShellScriptBin "touchpad-toggle" ''
    pkill -f 'on-screen-touchpad\.py' || exec ${touchpad}/bin/on-screen-touchpad
  '';

  #--- One DMS bar button per toggle
  button = id: name: icon: command:
    pkgs.runCommand "dms-${id}" {} ''
      mkdir $out
      substitute ${./ToggleWidget.qml} $out/ToggleWidget.qml \
        --subst-var-by command ${command} --subst-var-by icon ${icon}
      cat > $out/plugin.json <<'EOF'
      ${builtins.toJSON {
        inherit id name icon;
        description = "${name} on / off";
        version = "1.0.0";
        author = "nixos-config";
        type = "widget";
        capabilities = ["dankbar-widget"];
        component = "./ToggleWidget.qml";
        requires_dms = ">=2.0.0";
      }}
      EOF
    '';
in {
  #--------------------------------------------------------------------#
  #-- Keyboard
  #--------------------------------------------------------------------#
  home.packages = [osk-toggle touchpad-toggle];

  systemd.user.services.wvkbd = {
    Unit = {
      Description = "On-screen keyboard (wvkbd)";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${keyboard}";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  #--- Raises the keyboard and touchpad over DMS's launcher and polkit dialog
  systemd.user.services.osk-raise = {
    Unit = {
      Description = "Keep the on-screen keyboard and touchpad on top";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 -I ${./raise-watch.py}";
      Environment = "PATH=${lib.makeBinPath [config.programs.niri.package pkgs.procps]}";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  #--- Colours: wvkbd only reads them at start, so a theme change restarts it
  matugen.templates.wvkbd = {
    input = ./wvkbd-colors.sh;
    output = colors;
    postHook = "systemctl --user restart wvkbd.service";
  };

  #--- The touchpad panel watches this file itself
  matugen.templates.on-screen-touchpad = {
    input = ./touchpad.css.matugen;
    output = "${config.xdg.configHome}/on-screen-touchpad/style.css";
  };

  #--------------------------------------------------------------------#
  #-- Bar Buttons
  #--------------------------------------------------------------------#
  programs.dank-material-shell.plugins = {
    oskToggle.src =
      button "oskToggle" "On-screen keyboard" "keyboard" (lib.getExe osk-toggle);
    touchpadToggle.src =
      button "touchpadToggle" "On-screen touchpad" "touch_app" (lib.getExe touchpad-toggle);
  };
}
