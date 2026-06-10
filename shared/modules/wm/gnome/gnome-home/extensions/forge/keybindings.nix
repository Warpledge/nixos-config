#=====================================================================#
# FORGE EXTENSION KEYBINDINGS
#=====================================================================#
{lib, ...}: {
  dconf.settings = with lib.gvariant; {
    "org/gnome/shell/extensions/forge/keybindings" = {
      con-split-horizontal = mkEmptyArray type.string;
      con-split-layout-toggle = mkEmptyArray type.string;
      con-split-vertical = mkEmptyArray type.string;
      con-stacked-layout-toggle = mkEmptyArray type.string;
      con-tabbed-layout-toggle = mkEmptyArray type.string;
      con-tabbed-showtab-decoration-toggle = mkEmptyArray type.string;
      focus-border-toggle = ["<Super>x"];
      mod-mask-mouse-tile = "None";
      prefs-tiling-toggle = ["<Super>y"];
      window-gap-size-decrease = mkEmptyArray type.string;
      window-gap-size-increase = mkEmptyArray type.string;
      window-focus-down = ["<Super>Down"];
      window-focus-left = ["<Super>Left"];
      window-focus-right = ["<Super>Right"];
      window-focus-up = ["<Super>Up"];
      window-move-down = ["<Super><Shift>Down"];
      window-move-left = ["<Super><Shift>Left"];
      window-move-right = ["<Super><Shift>Right"];
      window-move-up = ["<Super><Shift>Up"];
      window-resize-bottom-decrease = mkEmptyArray type.string;
      window-resize-bottom-increase = mkEmptyArray type.string;
      window-resize-left-decrease = mkEmptyArray type.string;
      window-resize-left-increase = mkEmptyArray type.string;
      window-resize-right-decrease = mkEmptyArray type.string;
      window-resize-right-increase = mkEmptyArray type.string;
      window-resize-top-decrease = mkEmptyArray type.string;
      window-resize-top-increase = mkEmptyArray type.string;
      window-snap-center = mkEmptyArray type.string;
      window-snap-one-third-left = mkEmptyArray type.string;
      window-snap-one-third-right = mkEmptyArray type.string;
      window-snap-two-third-left = mkEmptyArray type.string;
      window-snap-two-third-right = mkEmptyArray type.string;
      window-swap-down = mkEmptyArray type.string;
      window-swap-last-active = mkEmptyArray type.string;
      window-swap-left = mkEmptyArray type.string;
      window-swap-right = mkEmptyArray type.string;
      window-swap-up = mkEmptyArray type.string;
      window-toggle-always-float = ["<Super>g"];
      window-toggle-float = ["<Super>Space"];
      workspace-active-tile-toggle = mkEmptyArray type.string;
    };
  };
}
