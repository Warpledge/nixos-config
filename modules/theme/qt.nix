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
    lib.mapAttrs (_: u: {config, ...}: {
      home.sessionVariables = {
        #--- Qt Theme Session Variables
        QT_STYLE_OVERRIDE = "kvantum";
        QT_QPA_PLATFORMTHEME = "qt6ct";
        QT_QPA_ICON_THEME_SEARCH_PATHS = "/run/current-system/sw/share/icons:\${HOME}/.icons";
      };

      qt = {
        enable = true;
        style.name = "kvantum";
        platformTheme.name = "qt6ct";

        #--- Icon Theme for Qt Apps (Quickshell/DMS, etc.)
        # Without this, QIcon::fromTheme() only sees the "hicolor" fallback,
        # so XDG icon names that aren't in hicolor (e.g. fcitx5's
        # "input-keyboard") render as broken icons in the DMS tray menu.
        qt6ctSettings = {
          Appearance = {
            icon_theme = "Papirus-Dark";
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

      #--- KDE Colour Scheme
      # KDE apps (Dolphin) take colours and icons from kdeglobals, not qt6ct;
      # upstream's Catppuccin scheme, in the flavour and accent Kvantum uses
      xdg.configFile."kdeglobals" = lib.mkIf u.fileBrowsers.dolphin {
        source = let
          inherit (config.catppuccin) flavor accent;
          scheme = pkgs.catppuccin-kde.override {
            flavour = [flavor];
            accents = [accent];
          };
          name = "Catppuccin${lib.toSentenceCase flavor}${lib.toSentenceCase accent}";
        in
          pkgs.runCommand "kdeglobals" {} ''
            cat ${scheme}/share/color-schemes/${name}.colors > $out
            printf '\n[Icons]\nTheme=Papirus-Dark\n' >> $out
          '';
      };
    })
    machine.users;
}
