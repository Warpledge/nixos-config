#=====================================================================#
# LAYER RULES (simplified format)
#=====================================================================#
{lib, ...}: let
  animations = import ./animations.nix;
  blur = import ./blur.nix;

  allRules = animations ++ blur;
in {
  wayland.windowManager.hyprland.settings.layer_rule = map (import ../luaRule.nix {inherit lib;}) allRules;
}
