#=====================================================================#
# WINDOW RULES (simplified format)
#=====================================================================#
_: let
  opacity = import ./opacity.nix;
  floating = import ./floating.nix;
  pinning = import ./pinning.nix;
  gaming = import ./gaming.nix;
  workspaces = import ./workspaces.nix;
  browser = import ./browser.nix;
  system = import ./system.nix;
  waydroid = import ./waydroid.nix;

  allRules = opacity ++ floating ++ pinning ++ gaming ++ workspaces ++ browser ++ system ++ waydroid;
in {
  wayland.windowManager.hyprland.settings.windowrule = allRules;
}
