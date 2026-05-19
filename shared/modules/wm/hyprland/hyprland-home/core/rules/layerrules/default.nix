#=====================================================================#
# LAYER RULES (simplified format)
#=====================================================================#
_:
let
  animations = import ./animations.nix;
  blur = import ./blur.nix;

  allRules = animations ++ blur;
in {
  wayland.windowManager.hyprland.settings.layerrule = allRules;
}
