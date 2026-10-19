#=====================================================================#
# VSCODIUM EDITOR CONFIGURATION
#=====================================================================#
{
  config,
  lib,
  pkgs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Editor Configuration
  #--------------------------------------------------------------------#
  programs.vscodium = {
    enable = true;

    #--- Catppuccin Mocha theme, no italics
    theme = "Catppuccin Mocha - No Italics";

    #--- Extensions
    extensions = with pkgs.vscode-extensions; [
      nixlanguageserver.nix
      biome.biome
    ];

    #--- User Settings
    settings = {
      #--- Editor Behavior
      "editor.fontSize" = 15;
      "editor.fontFamily" = "monospace";
      "editor.tabSize" = 2;
      "editor.wordWrap" = "on";
      "editor.formatOnSave" = true;
      "editor.defaultFormatter" = "biome.biome";
      "editor.inlayHints.enabled" = "on";
      "editor.cursorStyle" = "line";
      "editor.minimap.enabled" = false;
      "editor.scrollbar.vertical" = "auto";
      "editor.scrollbar.horizontal" = "hidden";

      #--- Window
      "window.titleBarStyle" = "custom";
      "window.menuBarVisibility" = "toggle";
      "window.autoDetectColorScheme" = true;

      #--- Workbench
      "workbench.colorTheme" = "Catppuccin Mocha - No Italics";
      "workbench.iconTheme" = "catppuccin-mocha";
      "workbench.startupEditor" = "none";
      "workbench.editor.wrap" = true;
      "workbench.settings.editor" = "json";

      #--- Terminal
      "terminal.integrated.fontSize" = 14;
      "terminal.integrated.fontFamily" = "monospace";
      "terminal.integrated.cursorStyle" = "line";

      #--- Git
      "git.autofetch" = true;
      "git.confirmSync" = false;

      #--- Telemetry (disabled)
      "telemetry.telemetryLevel" = "disallowed";
      "update.mode" = "none";

      #--- Nix
      "nix.buildTimeoutInMinutes" = 60;
      "nix.serverPath.nixd" = "nixd";
    };

    #--- Keybinds
    userSettings = {
      "keyboardshortcutsConverter.convertKeyboards" = false;
      "keybindings.disabled" = [
        #--- Disable Ctrl+Shift+P default (use Cmd+Shift+P)
        "workbench.action.commands.show"
      ];
    };

    userKeymaps = [
      {
        bindings = {
          "ctrl-q" = "editor.action.toggleComment";
          "shift-ctrl-v" = null;
          "shift-ctrl-c" = null;
        };
      }
    ];
  };

  #--------------------------------------------------------------------#
  #-- Additional Packages
  #--------------------------------------------------------------------#
  home.packages = [
    pkgs.nixd
  ];
}
