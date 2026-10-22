#=====================================================================#
# GTK THEME & ICON CONFIGURATION
#=====================================================================#
{
  lib,
  pkgs,
  machine,
  ...
}: {
  #--- Every user on the machine
  home-manager.users =
    lib.mapAttrs (_: _: {
      config,
      lib,
      ...
    }: let
      css = ''
        @import url("dank-colors.css");
        @define-color accent_color @accent_bg_color;
      '';
    in {
      #--------------------------------------------------------------------#
      #-- Theme, Font and Icon Theme
      #--------------------------------------------------------------------#
      # adw-gtk3 with DMS's matugen colours on top; DMS's live refresh only
      # finds the theme under ~/.local/share/themes
      gtk = {
        enable = true;
        theme = {
          package = pkgs.adw-gtk3;
          name = "adw-gtk3-dark";
        };
        # No adw-gtk3 import in gtk-4.0/gtk.css: its full libadwaita sheet would
        # load at user priority and override apps' own CSS
        gtk4.theme = null;
        # DMS's file sets accent_bg_color only; apps reading accent_color
        # (NixOS Settings) would get Adwaita's stock accent instead
        gtk3.extraCss = css;
        gtk4.extraCss = css;
        font = {
          inherit (config.stylix.fonts.sansSerif) package name;
          size = config.stylix.fonts.sizes.applications;
        };
        iconTheme = {
          package = pkgs.papirus-icon-theme;
          name = "Papirus-Dark";
        };
      };
      home.pointerCursor.gtk.enable = true;
      xdg.dataFile = lib.genAttrs ["themes/adw-gtk3" "themes/adw-gtk3-dark"] (t: {
        source = "${pkgs.adw-gtk3}/share/${t}";
      });

      #--- gtk.css as plain files: DMS only reloads GTK apps live when it can
      #--- read dank-colors.css in gtk.css, and it reads a link's target path
      xdg.configFile."gtk-3.0/gtk.css".enable = false;
      xdg.configFile."gtk-4.0/gtk.css".enable = false;
      home.activation.gtkCss = lib.hm.dag.entryAfter ["linkGeneration"] (
        lib.concatMapStrings (v: let
          src = config.xdg.configFile."gtk-${v}.0/gtk.css".source;
          f = "${config.xdg.configHome}/gtk-${v}.0/gtk.css";
        in ''
          if [[ ! -v DRY_RUN ]]; then
            mkdir -p "$(dirname "${f}")"
            rm -f "${f}"
            cp --no-preserve=mode ${src} "${f}"
          fi
        '') ["3" "4"]
      );

      #--------------------------------------------------------------------#
      #-- Icon Theme Packages
      #--------------------------------------------------------------------#
      home.packages = with pkgs; [
        adwaita-icon-theme
      ];

      #--------------------------------------------------------------------#
      #-- Icon Theme Symlink for Quickshell & Shells
      #--------------------------------------------------------------------#
      # Write index.theme instead of symlinking whole dir — allows the Stylix
      # cursor theme to be found by Xwayland alongside Papirus-Dark icons
      home.file.".icons/default/index.theme".text = ''
        [Icon Theme]
        Name=Default
        Inherits=${config.stylix.cursor.name},Papirus-Dark,hicolor
      '';
    })
    machine.users;
}
