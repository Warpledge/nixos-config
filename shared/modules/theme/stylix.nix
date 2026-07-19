#=====================================================================#
# STYLIX THEME CONFIGURATION
#=====================================================================#
{
  pkgs,
  config,
  lib,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Home Manager Theme
  #--------------------------------------------------------------------#
  home-manager.users.${username} = {
    stylix = lib.mkDefault {
      enable = true;
      autoEnable = true;

      #--- Disable version mismatch warnings
      enableReleaseChecks = true;

      targets = {
        #--- Enable targets
        vesktop.enable = true;
        mpv.enable = true;

        #--- Disable targets
        spicetify.enable = false; # have custom theme setup
        waybar.enable = false; # conflicts
        zed.enable = false; # handled by app
        kde.enable = false; # breaks KDE apps / Desktop
        forge.enable = false; # breaks gnome forge extension
        hyprlock.enable = false; # have custom theme
        mangohud.enable = false; # managed via programs.mangohud
        helix.enable = false;
        micro.enable = false;
        starship.enable = false;
        yazi.enable = false; # themed by Catppuccin port
        firefox.enable = false;
        floorp.enable = false;
        librewolf.enable = false;
        zen-browser.enable = false;

        dank-material-shell.enable = false;
        gnome.image.enable = false; # let GNOME Settings own the wallpaper

        vscode.profileNames = ["default"]; # needed for vscode
        zen-browser.profileNames = ["default"];
        firefox.profileNames = ["default"];
        floorp.profileNames = ["default"];
        librewolf.profileNames = ["default"];

        qt.enable = false;
        gtk = {
          enable = true;
          flatpakSupport.enable = true;
        };
      };
    };

    #--- Cursor
    # Explicit enable; relying on home.pointerCursor's implicit enable is deprecated.
    home.pointerCursor.enable = true;
  };
  #--------------------------------------------------------------------#
  #-- System Theme
  #--------------------------------------------------------------------#
  stylix = lib.mkDefault {
    #--- Core
    enable = true;
    autoEnable = true;
    polarity = "dark";

    #--- Disable version mismatch warnings
    enableReleaseChecks = true;

    targets = {
      chromium.enable = false;
      plymouth.enable = false;
      kmscon.enable = false;

      qt.enable = false;
      gtk.enable = true;
    };

    #--- Cursor
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = config.stylix.fonts.sansSerif;
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 13;
        desktop = 13;
        popups = 13;
        terminal = 13;
      };
    };

    #--- Global Theme
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    #--- Catppuccin Custom
    base16Scheme = {
      base00 = "1e1e2e"; # Default Background
      base01 = "181825"; # Lighter Background (Used for status bars, line numbers)
      base02 = "313244"; # Selection Background
      base03 = "6c7086"; # Comments, Invisibles, Line Highlighting
      base04 = "585b70"; # Dark Foreground (Used for status bars)
      base05 = "cdd6f4"; # Default Foreground, Caret, Delimiters, Operators
      base06 = "f5e0dc"; # Light Foreground (Not often used)
      base07 = "b4befe"; # Light Background (Not often used)
      base08 = "f38ba8"; # Variables, XML Tags, Markup Link Text, Markup Lists
      base09 = "fab387"; # Integers, Boolean, Constants, XML Attributes
      base0A = "f9e2af"; # Classes, Markup Bold, Search Text Background
      base0B = "a6e3a1"; # Strings, Inherited Class, Markup Code, Diff Inserted
      base0C = "94e2d5"; # Support, Regular Expressions, Escape Characters
      base0D = "89b4fa"; # Functions, Methods, Attribute IDs, Headings, Accent color
      base0E = "cba6f7"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
      base0F = "f2cdcd"; # Deprecated, Opening/Closing Embedded Language Tags
    };
  };
}
