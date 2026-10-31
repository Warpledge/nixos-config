#=====================================================================#
# ON-SCREEN KEYBOARD AND TOUCHPAD MODE
#=====================================================================#
#- For using the Z13 without its folio: wvkbd as the keyboard (full width,
#- translucent over niri's blur, touch-only), and a pad mode that turns the
#- whole screen above the keyboard into one big touchpad. The PAD key on the
#- keyboard (F13, niri bind) or the DMS bar button toggles pad mode; a swipe
#- up from the bottom edge (wm/touch-gestures.py) toggles the keyboard.
{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = "${config.xdg.configHome}/wvkbd/colors.sh";

  #--- Keyboard strip (logical px): wvkbd's height and the screen it leaves
  height = 390;
  #--- The DMS bar strip on top, which the touchpad must never swallow
  barStrip = 36;
  #--- Panel opacity (0-255). Under 255 wvkbd's own panel lets the blur through
  keyAlpha = 217;

  #--- The desktop layout, rebuilt for Ky (see wvkbd-layout.patch), plus:
  #- caps locks on a double-tap of shift (wvkbd-caps-shift.patch),
  #- the keys fill the window's height (wvkbd-rows-fill.patch),
  #- no pointer listener at all (only touches press keys),
  #- keys via uinput so niri's binds see the PAD key's F13 (wvkbd-uinput.patch;
  #- without it the PAD key is dead and no OSK key ever reaches a bind).
  wvkbd = pkgs.wvkbd.overrideAttrs (old: {
    makeFlags = (old.makeFlags or []) ++ ["LAYOUT=deskintl"];
    patches =
      (old.patches or [])
      ++ [
        ./wvkbd-layout.patch
        ./wvkbd-caps-shift.patch
        ./wvkbd-rows-fill.patch
        ./wvkbd-touch-only.patch
        ./wvkbd-uinput.patch
      ];
  });

  keyboard = pkgs.writeShellScript "wvkbd-start" ''
    WVKBD_COLORS=""
    [ -r "${colors}" ] && . "${colors}"
    # Type through uinput, so niri's binds, keyd and polkit prompts see the keys
    export WVKBD_UINPUT=1
    # shellcheck disable=SC2086 # one flag per word
    exec ${wvkbd}/bin/wvkbd-deskintl --hidden -H ${toString height} -L ${toString height} \
      --alpha ${toString keyAlpha} \
      --fn "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.popups}" \
      $WVKBD_COLORS
  '';

  osk-toggle = pkgs.writeShellScriptBin "osk-toggle" ''
    pkill --signal RTMIN -x wvkbd-deskintl
  '';

  pad-mode = pkgs.writeShellScriptBin "osk-pad-mode" ''
    pkill --signal USR2 -f 'on-screen-touchpad\.py'
  '';

  touchpad = pkgs.stdenv.mkDerivation {
    pname = "on-screen-touchpad";
    version = "2.0";
    dontUnpack = true;
    nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.gobject-introspection];
    buildInputs = [pkgs.gtk4 pkgs.gtk4-layer-shell];
    installPhase = ''
      install -Dm644 ${./touchpad.py} $out/share/on-screen-touchpad.py
      mkdir -p $out/bin
      makeWrapper ${pkgs.python3.withPackages (p: [p.evdev p.pygobject3])}/bin/python3 \
        $out/bin/on-screen-touchpad --add-flags $out/share/on-screen-touchpad.py
    '';
    # gtk4-layer-shell has to load before libwayland; the margins are the
    # keyboard strip (bottom) and the bar strip (top) the pad never covers
    preFixup = ''
      gappsWrapperArgs+=(--set LD_PRELOAD ${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so
        --set OSK_PAD_BOTTOM ${toString height}
        --set OSK_PAD_TOP ${toString barStrip})
    '';
    postFixup = ''
      wrapGApp $out/bin/on-screen-touchpad
    '';
    dontWrapGApps = true;
  };

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
        version = "2.0.0";
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
  home.packages = [osk-toggle pad-mode];

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

  #--- The touchpad daemon waits hidden; pad mode maps its window
  systemd.user.services.on-screen-touchpad = {
    Unit = {
      Description = "On-screen touchpad (pad mode daemon)";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${touchpad}/bin/on-screen-touchpad";
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

  #--- The touchpad daemon watches this file itself
  matugen.templates.on-screen-touchpad = {
    input = ./touchpad.css.matugen;
    output = "${config.xdg.configHome}/on-screen-touchpad/style.css";
  };

  #--------------------------------------------------------------------#
  #-- Niri: the PAD key's bind, and blur behind the keyboard
  #--------------------------------------------------------------------#
  niri.keybinds.osk-pad-mode = {
    key = "XF86Tools"; # xkb's keysym for KEY_F13; a bind on "F13" never fires
    title = "Touchpad mode on / off";
    action.spawn = ["${pad-mode}/bin/osk-pad-mode"];
  };

  #--- The keyboard paints a translucent panel; niri blurs what's under it
  programs.niri.settings.layer-rules = [
    {
      matches = [{namespace = "^wvkbd$";}];
      background-effect = {
        blur = true;
        xray = false;
      };
    }
  ];

  #--------------------------------------------------------------------#
  #-- Bar Buttons
  #--------------------------------------------------------------------#
  programs.dank-material-shell.plugins = {
    oskToggle.src =
      button "oskToggle" "On-screen keyboard" "keyboard" (lib.getExe osk-toggle);
    touchpadToggle.src =
      button "touchpadToggle" "Touchpad mode" "touch_app" (lib.getExe pad-mode);
  };
}
