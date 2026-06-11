{
  username,
  pkgs,
  ...
}: {
  home-manager.users.${username} = {
    home.sessionVariables = {
      #--- Qt Theme Session Variables
      QT_STYLE_OVERRIDE = "kvantum"; # Use Kvantum for Qt theme
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
      };
    };

    #--- Install qt6ct for Qt theming
    home.packages = with pkgs; [
      qt6Packages.qt6ct
    ];
  };
}
