#=====================================================================#
# JAPANESE INPUT METHOD (FCITX5 + MOZC)
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Input Method Engine
  #--------------------------------------------------------------------#
  # Fcitx5 + Mozc provides kana/kanji conversion (hiragana, katakana,
  # romaji → kanji) for typing Japanese system-wide. Toggle on/off with
  # Ctrl+Space. Locale + CJK fonts live in system/locale.nix + theme/fonts.nix.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      #--- Use the Wayland text-input frontend for native apps (Niri/Hyprland/GNOME)
      # while still exporting XMODIFIERS so XWayland/Wine VNs reach the IME via XIM.
      waylandFrontend = true;

      #--- Addons
      addons = with pkgs; [
        fcitx5-mozc # Japanese conversion engine (hiragana/katakana/kanji)
        fcitx5-gtk # GTK IM module integration
        kdePackages.fcitx5-configtool # GUI for tweaking input methods/hotkeys
        catppuccin-fcitx5 # Candidate-window theme to match Stylix (Mocha Mauve)
      ];

      #--------------------------------------------------------------------#
      #-- Declarative Configuration
      #--------------------------------------------------------------------#
      # Ship a ready-to-use group (US keyboard + Mozc) so Mozc works out of
      # the box without opening the config tool. Mozc's learned dictionary is
      # stored separately and persists normally.
      settings = {
        globalOptions = {
          "Hotkey/TriggerKeys"."0" = "Control+space"; # Toggle IME on/off
          Hotkey.EnumerateWithTriggerKeys = "True";
          Behavior.ActiveByDefault = "False"; # Start in direct (Latin) mode
        };

        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us"; # Plain US layout
          "Groups/0/Items/1".Name = "mozc"; # Japanese input
        };

        addons = {
          classicui.globalSection.Theme = "catppuccin-mocha-mauve";
        };
      };
    };
  };
}
