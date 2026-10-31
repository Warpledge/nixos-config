#=====================================================================#
# ON-SCREEN KEYBOARD AND TOUCHPAD MODE
#=====================================================================#
#- For using the Z13 without its folio: wvkbd as the keyboard (full width,
#- translucent over niri's blur, touch-only), and a pad mode (wm/touch-gestures.py)
#- that turns the whole screen above the keyboard into one big touchpad. The PAD
#- key on the keyboard (F13, niri bind) or the DMS bar button toggles pad mode; a
#- swipe up from the bottom edge (also there) toggles the keyboard.
{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = "${config.xdg.configHome}/wvkbd/colors.sh";

  #--- Keyboard strip (logical px); KEYBOARD_STRIP in wm/touch-gestures.py matches
  height = 390;
  #--- Panel opacity (0-255). Under 255 wvkbd's own panel lets the blur through
  keyAlpha = 217;

  #--- The desktop layout, rebuilt for Ky (see wvkbd-layout.patch), plus:
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
        ./wvkbd-rows-fill.patch
        ./wvkbd-touch-only.patch
        ./wvkbd-uinput.patch
        ./wvkbd-print-single-char.patch
        ./wvkbd-multitouch.patch
        ./wvkbd-swipe.patch
        ./wvkbd-glow.patch
        ./wvkbd-indicators.patch
        ./wvkbd-auto-open.patch
      ];
  });

  #--- Reads wvkbd's -o output; the dictionary path and tools it calls are set here
  autocorrect = pkgs.writeShellScript "osk-autocorrect-daemon" ''
    export DICPATH=${pkgs.hunspellDicts.en_US}/share/hunspell
    export PATH=${lib.makeBinPath [config.programs.niri.package pkgs.hunspell]}
    exec ${pkgs.python3.withPackages (p: [p.evdev p.symspellpy])}/bin/python3 ${./autocorrect.py}
  '';

  #--- autocorrect.py keeps the first, osk-swipe the second; their keys light from these
  autocorrectState = "${config.xdg.stateHome}/osk-autocorrect-on";
  swipeState = "${config.xdg.stateHome}/osk-swipe-on";
  #--- folio-watch.py reads the off switch and keeps the folio's state
  autoOffState = "${config.xdg.stateHome}/osk-auto-off";
  folioState = "${config.xdg.stateHome}/osk-folio-attached";

  keyboard = pkgs.writeShellScript "wvkbd-start" ''
    WVKBD_COLORS=""
    [ -r "${colors}" ] && . "${colors}"
    [ -e "${swipeState}" ] && export WVKBD_SWIPE=1
    { [ -e "${folioState}" ] || [ -e "${autoOffState}" ]; } && export WVKBD_IM_BLOCKED=1
    [ -e "${autocorrectState}" ] && export WVKBD_AUTOCORRECT=1
    # Type through uinput, so niri's binds, keyd and polkit prompts see the keys
    export WVKBD_UINPUT=1
    # shellcheck disable=SC2086 # one flag per word
    ${wvkbd}/bin/wvkbd-deskintl -o --auto --no-popup --hidden -H ${toString height} -L ${toString height} \
      --alpha ${toString keyAlpha} \
      --fn "${config.stylix.fonts.sansSerif.name}, Material Symbols Rounded ${toString config.stylix.fonts.sizes.popups}" \
      $WVKBD_COLORS | ${autocorrect}
  '';

  osk-toggle = pkgs.writeShellScriptBin "osk-toggle" ''
    pkill --signal RTMIN -x wvkbd-deskintl
  '';

  autocorrect-toggle = pkgs.writeShellScriptBin "osk-autocorrect" ''
    pkill --signal USR1 -f 'autocorrect\.py'
    pkill --signal RTMIN+2 -x wvkbd-deskintl
  '';

  swipe-toggle = pkgs.writeShellScriptBin "osk-swipe" ''
    if [ -e "${swipeState}" ]; then
      ${pkgs.coreutils}/bin/rm "${swipeState}"
    else
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "${swipeState}")"
      ${pkgs.coreutils}/bin/touch "${swipeState}"
      pkill --signal USR2 -f 'autocorrect\.py'
    fi
    pkill --signal RTMIN+1 -x wvkbd-deskintl
  '';

  #--- Off switch for opening on text fields
  auto-toggle = pkgs.writeShellScriptBin "osk-auto" ''
    if [ -e "${autoOffState}" ]; then
      ${pkgs.coreutils}/bin/rm "${autoOffState}"
      echo "On-screen keyboard opens on text fields"
    else
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "${autoOffState}")"
      ${pkgs.coreutils}/bin/touch "${autoOffState}"
      echo "On-screen keyboard stays closed on text fields"
    fi
  '';

  pad-mode = pkgs.writeShellScriptBin "osk-pad-mode" ''
    pkill --signal USR2 -f 'touch-gestures\.py'
  '';

  #--- One DMS bar button per toggle
  button = id: name: icon: command: visibility:
    pkgs.runCommand "dms-${id}" {} ''
      mkdir $out
      substitute ${./ToggleWidget.qml} $out/ToggleWidget.qml \
        --subst-var-by command ${command} --subst-var-by icon ${icon} \
        --subst-var-by visibility ${lib.escapeShellArg visibility}
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
  home.packages = [osk-toggle pad-mode autocorrect-toggle swipe-toggle auto-toggle];

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

  #--- Stops text fields opening the keyboard while the folio is on, and hides it
  systemd.user.services.osk-folio = {
    Unit = {
      Description = "Watch for the folio for the on-screen keyboard";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 -I ${./folio-watch.py}";
      Environment = "PATH=${lib.makeBinPath [pkgs.procps]}";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  #--- Raises the keyboard over DMS's launcher and polkit dialog
  systemd.user.services.osk-raise = {
    Unit = {
      Description = "Keep the on-screen keyboard on top";
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

  #--------------------------------------------------------------------#
  #-- Niri: the PAD key's bind, and blur behind the keyboard
  #--------------------------------------------------------------------#
  niri.keybinds.osk-pad-mode = {
    key = "XF86Tools"; # xkb's keysym for KEY_F13; a bind on "F13" never fires
    title = "Touchpad mode on / off";
    action.spawn = ["${pad-mode}/bin/osk-pad-mode"];
  };

  #--- The keys beside space: KEY_F14 and KEY_F15 are these keysyms in xkb
  niri.keybinds.osk-autocorrect = {
    key = "XF86Launch5";
    title = "Autocorrect on / off";
    action.spawn = ["${autocorrect-toggle}/bin/osk-autocorrect"];
  };

  niri.keybinds.osk-swipe = {
    key = "XF86Launch6";
    title = "Swipe typing on / off";
    action.spawn = ["${swipe-toggle}/bin/osk-swipe"];
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
      button "oskToggle" "On-screen keyboard" "keyboard" (lib.getExe osk-toggle)
      "test ! -e ${folioState}";
    touchpadToggle.src =
      button "touchpadToggle" "Touchpad mode" "touch_app" (lib.getExe pad-mode) "";
    autocorrectToggle.src =
      button "autocorrectToggle" "Autocorrect" "spellcheck" (lib.getExe autocorrect-toggle) "";
  };
}
