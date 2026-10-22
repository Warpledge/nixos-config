{
  config,
  lib,
  machine,
  pkgs,
  ...
}: let
  inherit (config.stylix) fonts;
in {
  #--- Every user on the machine
  home-manager.users =
    lib.mapAttrs (_: u: {
      config,
      lib,
      ...
    }: {
      home.sessionVariables = {
        #--- Qt Theme Session Variables
        QT_QPA_PLATFORMTHEME = "qt6ct";
        QT_QPA_ICON_THEME_SEARCH_PATHS = "/run/current-system/sw/share/icons:\${HOME}/.icons";
      };

      qt = {
        enable = true;
        platformTheme.name = "qt6ct";

        #--- Icon Theme for Qt Apps (Quickshell/DMS, etc.)
        # Without this, QIcon::fromTheme() only sees the "hicolor" fallback,
        # so XDG icon names that aren't in hicolor (e.g. fcitx5's
        # "input-keyboard") render as broken icons in the DMS tray menu.
        qt6ctSettings = {
          Appearance = {
            icon_theme = "Papirus-Dark";
            #--- Colours: written by DMS's matugen on each theme change
            style = "Fusion";
            custom_palette = true;
            color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/matugen.conf";
          };
          # Stylix's qt target (off) writes these; same format as its module
          Fonts = {
            general = ''"${fonts.sansSerif.name},${toString fonts.sizes.applications}"'';
            fixed = ''"${fonts.monospace.name},${toString fonts.sizes.applications}"'';
          };
        };
      };

      #--- Install qt6ct for Qt theming
      home.packages = with pkgs; [
        qt6Packages.qt6ct
      ];

      #--- qt6ct.conf as a plain file: DMS touches it after a theme change so
      #--- running Qt apps reload, which fails on a read-only store link
      home.activation.qt6ctConf = lib.hm.dag.entryAfter ["linkGeneration"] (let
        f = "${config.xdg.configHome}/qt6ct/qt6ct.conf";
      in ''
        if [[ ! -v DRY_RUN ]]; then
          mkdir -p "$(dirname "${f}")"
          rm -f "${f}"
          cp --no-preserve=mode ${config.xdg.configFile."qt6ct/qt6ct.conf".source} "${f}"
        fi
      '');

      #--- KDE Colour Scheme
      # KDE apps (Dolphin) take colours and icons from kdeglobals, not qt6ct;
      # upstream's Catppuccin Mocha Mauve scheme, fixed (not matugen's).
      # [UiSettings] picks it by name: unset, KDE apps outside Plasma fall back
      # to Breeze Light. Alternate rows are made transparent (no banding).
      xdg = lib.mkMerge [
        {configFile."qt6ct/qt6ct.conf".enable = false;} # written by qt6ctConf
        (lib.mkIf u.fileBrowsers.dolphin (let
          flavor = "mocha";
          accent = "mauve";
          name = "Catppuccin${lib.toSentenceCase flavor}${lib.toSentenceCase accent}";
          upstream = pkgs.catppuccin-kde.override {
            flavour = [flavor];
            accents = [accent];
          };
          # Base (30,30,46) becomes Stylix's base00, as in stylix.nix
          base00 = with config.lib.stylix.colors; "${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}";
          scheme = pkgs.runCommand "${name}.colors" {} ''
            awk '/^\[/ { view = ($0 == "[Colors:View]") }
                 /=30,30,46$/ { sub(/30,30,46$/, "${base00}") }
                 view && /^BackgroundAlternate=/ { $0 = $0 ",0" } 1' \
              ${upstream}/share/color-schemes/${name}.colors > $out
          '';
        in {
          dataFile."color-schemes/${name}.colors".source = scheme;
          configFile."kdeglobals".source = pkgs.runCommand "kdeglobals" {} ''
            cat ${scheme} > $out
            printf '\n[Icons]\nTheme=Papirus-Dark\n' >> $out
            printf '\n[UiSettings]\nColorScheme=${name}\n' >> $out
          '';
        }))
      ];
    })
    machine.users;
}
