#=====================================================================#
# VSCODIUM EDITOR CONFIGURATION
#=====================================================================#
#- Stylix's vscodium target sets the theme and fonts (theme/stylix.nix).
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Editor Configuration
  #--------------------------------------------------------------------#
  programs.vscodium = {
    enable = true;

    profiles.default = {
      #--- Extensions
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];

      #--- User Settings
      userSettings = {
        #--- Editor Behavior
        "editor.tabSize" = 2;
        "editor.wordWrap" = "on";
        "editor.inlayHints.enabled" = "on";
        "editor.cursorStyle" = "line";
        "editor.minimap.enabled" = false;
        "editor.scrollbar.vertical" = "auto";
        "editor.scrollbar.horizontal" = "hidden";

        #--- Window
        "window.titleBarStyle" = "custom";
        "window.menuBarVisibility" = "toggle";

        #--- Workbench
        "workbench.startupEditor" = "none";
        "workbench.editor.wrap" = true;
        "workbench.settings.editor" = "json";

        #--- Terminal
        "terminal.integrated.cursorStyle" = "line";

        #--- Git
        "git.autofetch" = true;
        "git.confirmSync" = false;

        #--- Telemetry (disabled)
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";

        #--- Nix (nix-ide through nixd)
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- Additional Packages
  #--------------------------------------------------------------------#
  home.packages = [
    pkgs.nixd
  ];
}
