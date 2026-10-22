#=====================================================================#
# DOLPHIN FILE BROWSER CONFIGURATION
#=====================================================================#
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.kdePackages) dolphin kconfig;
  state = "${config.xdg.stateHome}/dolphin-declared";
  uiDir = "${config.xdg.dataHome}/kxmlgui5/dolphin";

  #--- Settings that differ from Dolphin's defaults (src/settings/*.kcfg)
  # file, group (nested groups split on /), key, value
  rc = file: group: key: value: {inherit file group key value;};
  settings = [
    (rc "dolphinrc" "General" "DoubleClickViewAction" "none")
    (rc "dolphinrc" "General" "ShowStatusBar" "FullWidth")
    (rc "dolphinrc" "General" "ShowZoomSlider" "true")
    (rc "dolphinrc" "DetailsMode" "PreviewSize" "16")
    (rc "dolphinrc" "IconsMode" "PreviewSize" "128")
    (rc "dolphinrc" "InformationPanel" "previewsShown" "false")
    (rc "dolphinrc" "InformationPanel" "showHovered" "false")
    (rc "dolphinrc" "KFileDialog Settings" "Places Icons Auto-resize" "false")
    (rc "dolphinrc" "KFileDialog Settings" "Places Icons Static Size" "22")
    (rc "dolphinrc" "MainWindow/Toolbar mainToolBar" "IconSize" "16")
    (rc "dolphinrc" "MainWindow/Toolbar mainToolBar" "ToolButtonStyle" "IconOnly")
    (rc "dolphinrc" "Toolbar mainToolBar" "IconSize" "16")
    (rc "dolphinrc" "Toolbar mainToolBar" "ToolButtonStyle" "IconOnly")
    (rc "dolphinrc" "PreviewSettings" "Plugins" (lib.concatStringsSep "," [
      "appimagethumbnail"
      "audiothumbnail"
      "blenderthumbnail"
      "comicbookthumbnail"
      "cursorthumbnail"
      "djvuthumbnail"
      "ebookthumbnail"
      "exrthumbnail"
      "directorythumbnail"
      "fontthumbnail"
      "imagethumbnail"
      "jpegthumbnail"
      "kraorathumbnail"
      "windowsexethumbnail"
      "windowsimagethumbnail"
      "mobithumbnail"
      "opendocumentthumbnail"
      "gsthumbnail"
      "rawthumbnail"
      "svgthumbnail"
      "ffmpegthumbs"
    ]))
    # Context menu entries are shown unless set false
    (rc "kservicemenurc" "Show" "hidefileitemaction" "false")
  ];

  #--- Toolbar and shortcuts
  # Patched into the shipped dolphinui.rc so its version always matches;
  # an older local file loses its toolbar. "" or "; " clears a shortcut.
  shortcuts = {
    compact = "";
    copy_location = "Meta+Ctrl+C";
    edit_cut = "Ctrl+X; ";
    file_close = "Alt+Q; Ctrl+Esc";
    file_quit = "; ";
    open_terminal = "";
    options_configure = "";
    options_configure_keybinding = "";
    replace_location = "Ctrl+L; ";
    show_terminal_panel = "";
  };
  shortcutXml = lib.concatStringsSep "\\n" (lib.mapAttrsToList
    (name: key: ''<Action name="${name}" shortcut="${key}"/>'')
    shortcuts);
  ui = pkgs.runCommand "dolphinui.rc" {} ''
    tar -xOf ${dolphin.src} --wildcards '*/src/dolphinui.rc' > ui.rc
    sed -e '/<ToolBar/,/<\/ToolBar>/s|^\( *\)<Action name="go_forward" */>|&\n\1<Action name="go_up" />|' \
      -e 's|^ *</ActionProperties>|${shortcutXml}\n&|' ui.rc > $out
    grep -q '"go_up"' $out
    grep -q 'shortcut=' $out
  '';

  #--- Convert Media service menu
  convertMedia = pkgs.writeShellApplication {
    name = "convert-media";
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
      gnugrep
      kdePackages.kdialog
      libnotify
      util-linux # setsid
    ];
    text = builtins.readFile ./convert-media.sh;
  };
  mediaTypes = [
    "video/mp4"
    "video/x-matroska"
    "video/webm"
    "video/x-msvideo"
    "video/quicktime"
    "video/mpeg"
    "video/x-flv"
    "video/x-ms-wmv"
    "video/3gpp"
    "video/ogg"
    "audio/mpeg"
    "audio/mp4"
    "audio/x-m4a"
    "audio/flac"
    "audio/x-flac"
    "audio/x-wav"
    "audio/wav"
    "audio/ogg"
    "audio/x-vorbis+ogg"
    "audio/aac"
    "audio/x-aac"
  ];
in {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  # Colours and icons come from theme/qt.nix (Kvantum, qt6ct, kdeglobals)

  home.packages = with pkgs; [
    dolphin
    kdePackages.ark # archives; adds Compress/Extract to Dolphin's context menu
    kdePackages.ffmpegthumbs # video previews (ffmpegthumbs)
    kdePackages.kdegraphics-thumbnailers # PDF/PS, RAW, Blender, Mobipocket previews
  ];

  #--------------------------------------------------------------------#
  #-- Application Menu
  #--------------------------------------------------------------------#
  # KService lists apps from this menu; outside Plasma there is none, which
  # leaves Dolphin's Open With menu empty
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
     "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';

  #--------------------------------------------------------------------#
  #-- Settings, Toolbar & Shortcuts
  #--------------------------------------------------------------------#
  # Written into Dolphin's own files, which it keeps saving to. A value changed
  # in Dolphin survives rebuilds; one still at the last applied value follows
  # the repo. Same for dolphinui.rc as a whole.

  home.activation.dolphinDefaults = lib.hm.dag.entryAfter ["linkGeneration"] ''
    if [[ -v DRY_RUN ]]; then
      echo "Would apply Dolphin defaults"
    else
      mkdir -p "${state}" "${uiDir}"
      old="${state}/settings"
      new="${state}/settings.new"
      touch "$old"
      : > "$new"
      dolphinSet() {
        local f="${config.xdg.configHome}/$1" id="$1|$2|$3=" g cur prev args=()
        local -a gs
        IFS=/ read -ra gs <<< "$2"
        for g in "''${gs[@]}"; do args+=(--group "$g"); done
        cur="$(${kconfig}/bin/kreadconfig6 --file "$f" "''${args[@]}" --key "$3")"
        prev="$(grep -F -m1 -- "$id" "$old" || true)"
        prev="''${prev#"$id"}"
        if [[ -z $cur || $cur == "$prev" ]]; then
          ${kconfig}/bin/kwriteconfig6 --file "$f" "''${args[@]}" --key "$3" "$4"
        fi
        printf '%s%s\n' "$id" "$4" >> "$new"
      }
      ${lib.concatMapStringsSep "\n" (s: "dolphinSet ${lib.escapeShellArgs [s.file s.group s.key s.value]}")
      settings}
      mv "$new" "$old"

      if [[ ! -e "${uiDir}/dolphinui.rc" ]] \
        || ${pkgs.diffutils}/bin/cmp -s "${uiDir}/dolphinui.rc" "${state}/dolphinui.rc"; then
        cp --no-preserve=mode ${ui} "${uiDir}/dolphinui.rc"
      fi
      cp --no-preserve=mode ${ui} "${state}/dolphinui.rc"
    fi
  '';

  #--------------------------------------------------------------------#
  #-- Service Menus
  #--------------------------------------------------------------------#
  # KIO only loads user service menus that are executable

  xdg.dataFile."kio/servicemenus/convert-video.desktop" = {
    executable = true;
    text = ''
      [Desktop Entry]
      Type=Service
      X-KDE-ServiceTypes=KonqPopupMenu/Plugin
      MimeType=${lib.concatMapStrings (t: "${t};") mediaTypes}
      Actions=convertVideo
      X-KDE-Priority=TopLevel

      [Desktop Action convertVideo]
      Name=Convert Media
      Icon=video-x-generic
      Exec=${lib.getExe convertMedia} %f
    '';
  };
}
