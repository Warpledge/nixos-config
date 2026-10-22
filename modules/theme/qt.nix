{
  config,
  inputs,
  lib,
  machine,
  pkgs,
  ...
}: let
  inherit (config.stylix) fonts;
  dmsTemplates = "${inputs.dms}/quickshell/matugen/templates";
in {
  #--- Every user on the machine
  home-manager.users =
    lib.mapAttrs (_: _: {
      config,
      lib,
      ...
    }: let
      cfg = config.xdg.configHome;
      #--- Same settings for qt5ct (Qt 5 apps) and qt6ct (Qt 6 apps)
      qtctSettings = v: {
        Appearance = {
          icon_theme = "Papirus-Dark";
          #--- Colours: written by DMS's matugen on each theme change
          style = "Fusion";
          custom_palette = true;
          color_scheme_path = "${cfg}/${v}/colors/matugen.conf";
        };
        # Stylix's qt target (off) writes these; same format as its module
        Fonts = {
          general = ''"${fonts.sansSerif.name},${toString fonts.sizes.applications}"'';
          fixed = ''"${fonts.monospace.name},${toString fonts.sizes.applications}"'';
        };
      };
    in {
      home.sessionVariables = {
        #--- Qt Theme Session Variables
        QT_QPA_ICON_THEME_SEARCH_PATHS = "/run/current-system/sw/share/icons:\${HOME}/.icons";
      };

      qt = {
        enable = true;
        # QT_QPA_PLATFORMTHEME=qt5ct: Qt 5 apps load qt5ct, and qt6ct's plugin
        # answers to the same name for Qt 6 apps
        platformTheme.name = "qtct";

        #--- Icon Theme for Qt Apps (Quickshell/DMS, etc.)
        # Without this, QIcon::fromTheme() only sees the "hicolor" fallback,
        # so XDG icon names that aren't in hicolor (e.g. fcitx5's
        # "input-keyboard") render as broken icons in the DMS tray menu.
        qt5ctSettings = qtctSettings "qt5ct";
        qt6ctSettings = qtctSettings "qt6ct";
      };

      #--- Install qt6ct for Qt theming
      home.packages = with pkgs; [
        qt6Packages.qt6ct
      ];

      #--- qt5ct.conf and qt6ct.conf as plain files: touching one makes running
      #--- Qt apps reload their palette, which fails on a read-only store link
      home.activation.qtctConf = lib.hm.dag.entryAfter ["linkGeneration"] (
        lib.concatMapStrings (v: let
          f = "${cfg}/${v}/${v}.conf";
        in ''
          if [[ ! -v DRY_RUN ]]; then
            mkdir -p "$(dirname "${f}")"
            rm -f "${f}"
            cp --no-preserve=mode ${config.xdg.configFile."${v}/${v}.conf".source} "${f}"
          fi
        '') ["qt5ct" "qt6ct"]
      );
      xdg.configFile."qt5ct/qt5ct.conf".enable = false;
      xdg.configFile."qt6ct/qt6ct.conf".enable = false;

      matugen.templates = {
        #--- DMS touches only qt6ct.conf after a theme change; this does qt5ct's
        #--- (DMS's own qt5ct template is off in its settings.json)
        qt5ct = {
          input = "${dmsTemplates}/qtct-colors.conf";
          output = "${cfg}/qt5ct/colors/matugen.conf";
          postHook = "touch ${cfg}/qt5ct/qt5ct.conf";
        };

        #--- KDE Colour Scheme
        # KDE apps (Dolphin, Ark) take colours and icons from kdeglobals, not
        # qtct: DMS's KDE scheme, read at app start. [UiSettings] picks it by
        # name: unset, KDE apps outside Plasma fall back to Breeze Light.
        # Alternate rows are made transparent (no banding).
        kdeglobals = {
          input = pkgs.runCommand "kdeglobals" {} ''
            awk '/^\[/ { view = ($0 == "[Colors:View]") }
                 view && /^BackgroundAlternate=/ { $0 = $0 ",0" } 1' \
              ${dmsTemplates}/kcolorscheme.colors > $out
            printf '\n[Icons]\nTheme=Papirus-Dark\n' >> $out
            printf '\n[UiSettings]\nColorScheme=DankMatugen\n' >> $out
          '';
          output = "${cfg}/kdeglobals";
        };
      };
    })
    machine.users;
}
