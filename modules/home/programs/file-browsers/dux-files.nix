#=====================================================================#
# DUX FILES (DUX-FILES) FILE BROWSER CONFIGURATION
#=====================================================================#
{config, lib, pkgs, inputs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages & Modules
  #--------------------------------------------------------------------#

  imports = [
    inputs.dux-files.homeModules.dux-files
  ];

  programs.dux-files = {
    enable = true;

    # Keep a resident instance so windows open fast and the portal answers at once
    systemd.enable = true;

    #--- UI settings — declared defaults, mutable (GUI can still edit)
    settings = {
      animationDuration = 250;
      clickToOpen = "double";
      closeBehavior = "quit";
      colorSource = "auto";
      confirmTrash = true;
      defaultSort = "name";
      defaultSortDescending = false;
      defaultView = "columns";
      dragAction = "auto";
      enableRippleEffects = true;
      extractOnOpen = true;
      focusRingColor = "primary";
      focusRingEnabled = false;
      focusRingWidth = 2;
      folderCounts = true;
      foldersFirst = true;
      fontScale = 1;
      fontWeight = 500;
      gtkBookmarksOffered = true;
      language = "";
      listTyping = "jump";
      mountOnClick = true;
      networkThumbnails = false;
      openLocationIn = "current";
      presetTheme = "purple";
      radiusStrength = 50;
      recentFiles = false;
      reduceMotion = false;
      registerFileManager = true;
      rememberFolderViews = true;
      searchExcludes = [];
      searchHidden = false;
      showHidden = true;
      showSystemPartitions = false;
      sidebarCollapsed = false;
      springBounce = 1;
      terminal = "";
      themeMode = "auto";
      thumbnailSizeLimitMb = 64;
      thumbnails = true;
      vimKeys = false;
      windowTitleBars = true;
    };
  };

  #--------------------------------------------------------------------#
  #-- Bookmarks
  #--------------------------------------------------------------------#

  # Dux Files reads ~/.config/gtk-3.0/bookmarks on first launch as a seed,
  # then manages its own ~/.config/dfiles/bookmarks.json from there.
  # We write the native file declaratively so bookmarks appear immediately
  # (no need to wait for the first-run import).
  home.file.".config/dfiles/bookmarks.json".text =
    let
      home = config.home.homeDirectory;
      mkBookmark = path: label: {
        path = "${home}/${lib.removePrefix "file://${home}/" path}";
        inherit label;
        icon = "";
      };
    in
    builtins.toJSON {
      version = 2;
      bookmarks = [
        (mkBookmark "file://${home}/Downloads" "Downloads")
        (mkBookmark "file://${home}/Documents" "Documents")
        (mkBookmark "file://${home}/Pictures" "Pictures")
        (mkBookmark "file://${home}/Videos" "Videos")
        (mkBookmark "file://${home}/Games" "Games")
        (mkBookmark "file://${home}/.local/share" "Local")
        (mkBookmark "file://${home}/.local/share/Steam/steamapps/common" "Steam")
        (mkBookmark "file://${home}/.local/share/Terraria/tModLoader" "tModLoader")
      ];
    };
}
