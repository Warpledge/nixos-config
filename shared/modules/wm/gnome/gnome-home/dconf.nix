#=====================================================================#
# GNOME DCONF SETTINGS
#=====================================================================#
{lib, ...}: let
  inherit (lib.gvariant) mkInt32 mkUint32;
in {
  #--------------------------------------------------------------------#
  #-- dconf Settings
  #--------------------------------------------------------------------#
  dconf.settings = with lib.gvariant; {
    #--- Desktop Preferences
    "org/gnome/desktop/wm/preferences".focus-mode = "sloppy"; # focus follows cursor
    "org/gnome/desktop/applications/file-manager".exec = "nautilus";
    "org/gnome/desktop/default-applications/terminal".exec = "kitty";
    "org/gnome/desktop/lockdown".disable-printing = true; # disable printing services
    "org/gnome/desktop/calendar".show-weekdate = true;
    "org/gnome/desktop/media-handling".automount = true;
    "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";
    "org/gnome/desktop/privacy".remember-recent-files = false;
    "org/gnome/desktop/screensaver".lock-enabled = true;
    "org/gnome/desktop/session".idle-delay = mkUint32 300;
    "org/gnome/desktop/notifications".show-in-lock-screen = false;

    #--- Mutter (Window Manager)
    "org/gnome/mutter" = {
      check-alive-timeout = lib.hm.gvariant.mkUint32 0;
      workspaces-only-on-primary = true;
      edge-tiling = true;
      attach-modal-dialogs = true;
      experimental-features = [
        "variable-refresh-rate"
        "hdr-display"
      ];
    };

    #--- Power Management
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "blank";
      sleep-inactive-battery-type = "blank";
      sleep-inactive-ac-timeout = mkInt32 300;
      sleep-inactive-battery-timeout = mkInt32 150;
      power-button-action = "interactive";
      idle-dim = true;
      idle-brightness = mkInt32 30;
      idle-delay = mkUint32 120;
    };

    #--- File Manager
    "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
    "org/gnome/nautilus/list-view" = {
      use-tree-view = true;
      default-zoom-level = "small";
    };
    "org/gtk/gtk4/settings/file-chooser" = {
      sort-directories-first = true;
      show-hidden = true;
      view-type = "list";
    };

    #--- Clock
    "org/gnome/desktop/interface" = {
      clock-format = "12h";
      clock-show-date = false;
      clock-show-seconds = false;
      clock-show-weekday = false;
      enable-hot-corners = false;
      color-scheme = "prefer-dark";
      show-battery-percentage = true;
      accent-color = "purple";
    };

    #--- Shell
    "org/gnome/shell" = {
      disable-user-extensions = false;
      favorite-apps = mkEmptyArray type.string;
      last-selected-power-profile = "performance";
    };

    "org/gnome/mutter".dynamic-workspaces = false;

    #--- Touchpad
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
    };

    #--- Workspaces
    "org/gnome/desktop/wm/preferences" = {
      resize-with-right-button = true;
      num-workspaces = 9;
      workspace-names = [
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
      ];
      button-layout = "appmenu:close"; # remove minimize and maximize buttons
    };

    #--- Keybinds
    "org/gnome/settings-daemon/plugins/media-keys" = {
      help = mkEmptyArray type.string;
      logout = ["<Control><Alt>Delete"];
      magnifier = mkEmptyArray type.string;
      magnifier-zoom-in = mkEmptyArray type.string;
      magnifier-zoom-out = mkEmptyArray type.string;
      screenreader = mkEmptyArray type.string;

      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>b";
      command = "helium";
      name = "Web Browser";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>e";
      command = "nautilus";
      name = "File Manager";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Super>c";
      command = "zeditor";
      name = "Zed Editor";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      binding = "<Super><Shift>d";
      command = "discord";
      name = "Discord";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      binding = "<Super>Return";
      command = "kitty";
      name = "Terminal";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      binding = "<Super><Shift>r";
      command = "resources";
      name = "Resources";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
      binding = "<Super><Shift>s";
      command = "steam";
      name = "Steam";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
      binding = "<Super><Shift>m";
      command = "spotify";
      name = "Spotify";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8" = {
      binding = "<Super><Shift>h";
      command = "heroic";
      name = "Heroic Games Launcher";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9" = {
      binding = "<Super><Shift>g";
      command = "lutris";
      name = "Lutris";
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = ["<Super>q"]; # kill window
      show-application = ["<Alt>Tab"];
      toggle-fullscreen = ["<Super>f"];
      always-on-top = ["<Super>t"];

      #--- Switch Workspaces
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      switch-to-workspace-5 = ["<Super>5"];
      switch-to-workspace-6 = ["<Super>6"];
      switch-to-workspace-7 = ["<Super>7"];
      switch-to-workspace-8 = ["<Super>8"];
      switch-to-workspace-9 = ["<Super>9"];
      #--- Move Window to Workspace
      move-to-workspace-1 = ["<Super><Shift>1"];
      move-to-workspace-2 = ["<Super><Shift>2"];
      move-to-workspace-3 = ["<Super><Shift>3"];
      move-to-workspace-4 = ["<Super><Shift>4"];
      move-to-workspace-5 = ["<Super><Shift>5"];
      move-to-workspace-6 = ["<Super><Shift>6"];
      move-to-workspace-7 = ["<Super><Shift>7"];
      move-to-workspace-8 = ["<Super><Shift>8"];
      move-to-workspace-9 = ["<Super><Shift>9"];

      #--- Disabled Keybinds
      switch-applications-backward = mkEmptyArray type.string;
      active-window-menu = mkEmptyArray type.string;
      begin-move = mkEmptyArray type.string;
      begin-resize = mkEmptyArray type.string;
      cycle-group = mkEmptyArray type.string;
      cycle-group-backward = mkEmptyArray type.string;
      cycle-panels = mkEmptyArray type.string;
      cycle-panels-backward = mkEmptyArray type.string;
      cycle-windows = mkEmptyArray type.string;
      cycle-windows-backward = mkEmptyArray type.string;
      lower = mkEmptyArray type.string;
      maximize = mkEmptyArray type.string;
      maximize-horizontally = mkEmptyArray type.string;
      maximize-vertically = mkEmptyArray type.string;
      minimize = mkEmptyArray type.string;
      move-to-center = mkEmptyArray type.string;
      move-to-corner-ne = mkEmptyArray type.string;
      move-to-corner-nw = mkEmptyArray type.string;
      move-to-corner-se = mkEmptyArray type.string;
      move-to-corner-sw = mkEmptyArray type.string;
      move-to-monitor-down = mkEmptyArray type.string;
      move-to-monitor-left = mkEmptyArray type.string;
      move-to-monitor-right = mkEmptyArray type.string;
      move-to-monitor-up = mkEmptyArray type.string;
      move-to-workspace-last = mkEmptyArray type.string;
      panel-main-menu = mkEmptyArray type.string;
      panel-run-dialog = mkEmptyArray type.string;
      raise = mkEmptyArray type.string;
      raise-or-lower = mkEmptyArray type.string;
      set-spew-mark = mkEmptyArray type.string;
      show-desktop = mkEmptyArray type.string;
      switch-group = mkEmptyArray type.string;
      switch-group-backward = mkEmptyArray type.string;
      switch-input-source = mkEmptyArray type.string;
      switch-input-source-backward = mkEmptyArray type.string;
      switch-panels = mkEmptyArray type.string;
      switch-panels-backward = mkEmptyArray type.string;
      switch-to-workspace-last = mkEmptyArray type.string;
      switch-windows = mkEmptyArray type.string;
      switch-windows-backward = mkEmptyArray type.string;
      toggle-above = mkEmptyArray type.string;
      toggle-maximized = mkEmptyArray type.string;
      toggle-on-all-workspaces = mkEmptyArray type.string;
      unmaximize = mkEmptyArray type.string;

      # Disable default window movement controls
      move-to-workspace-up = mkEmptyArray type.string;
      move-to-workspace-down = mkEmptyArray type.string;
      move-to-workspace-left = mkEmptyArray type.string;
      move-to-workspace-right = mkEmptyArray type.string;

      # Disable default window focus controls
      switch-to-workspace-up = mkEmptyArray type.string;
      switch-to-workspace-down = mkEmptyArray type.string;
      switch-to-workspace-left = mkEmptyArray type.string;
      switch-to-workspace-right = mkEmptyArray type.string;

      # Also disable any directional window movement keys
      move-to-side-n = mkEmptyArray type.string;
      move-to-side-s = mkEmptyArray type.string;
      move-to-side-e = mkEmptyArray type.string;
      move-to-side-w = mkEmptyArray type.string;
    };

    "org/gnome/shell/keybindings" = {
      screenshot = ["<Shift>Print"];
      screenshot-window = ["<Alt>Print"];
      show-screen-recording-ui = ["<Super>Print"];
      show-screenshot-ui = ["Print"];
      toggle-application-view = ["<Super>a"];

      #--- Disabled Keybinds
      focus-active-notification = mkEmptyArray type.string;
      open-new-window-application-1 = mkEmptyArray type.string;
      open-new-window-application-2 = mkEmptyArray type.string;
      open-new-window-application-3 = mkEmptyArray type.string;
      open-new-window-application-4 = mkEmptyArray type.string;
      open-new-window-application-5 = mkEmptyArray type.string;
      open-new-window-application-6 = mkEmptyArray type.string;
      open-new-window-application-7 = mkEmptyArray type.string;
      open-new-window-application-8 = mkEmptyArray type.string;
      open-new-window-application-9 = mkEmptyArray type.string;
      Shift-overview-down = mkEmptyArray type.string;
      shift-overview-up = mkEmptyArray type.string;
      switch-to-application-1 = mkEmptyArray type.string;
      switch-to-application-2 = mkEmptyArray type.string;
      switch-to-application-3 = mkEmptyArray type.string;
      switch-to-application-4 = mkEmptyArray type.string;
      switch-to-application-5 = mkEmptyArray type.string;
      switch-to-application-6 = mkEmptyArray type.string;
      switch-to-application-7 = mkEmptyArray type.string;
      switch-to-application-8 = mkEmptyArray type.string;
      switch-to-application-9 = mkEmptyArray type.string;
      toggle-message-tray = mkEmptyArray type.string;
      toggle-overview = mkEmptyArray type.string;
      toggle-quick-settings = mkEmptyArray type.string;
    };
  };
}
