{
  config,
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
    };

    #--- Install qt6ct for Qt theming
    home.packages = with pkgs; [
      qt6Packages.qt6ct
    ];
  };
}
