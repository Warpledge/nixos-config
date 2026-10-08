#=====================================================================#
# LAYER RULES (simplified format)
#=====================================================================#
{lib, ...}: let
  animations = import ./animations.nix;
  blur = import ./blur.nix;

  allRules =
    animations
    ++ blur
    ++ [
      #--- Privacy: blocked from screenshots and screen recording (mirrors niri)
      "match:namespace ^dms:(clipboard|notification-popup)$, no_screen_share on"
    ];
in {
  wayland.windowManager.hyprland.settings.layer_rule = map (import ../luaRule.nix {inherit lib;}) allRules;
}
