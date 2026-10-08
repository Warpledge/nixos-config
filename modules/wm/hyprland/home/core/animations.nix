#=====================================================================#
# HYPRLAND ANIMATIONS
#=====================================================================#
{lib, ...}: let
  inherit (builtins) elemAt fromJSON;
  fields = lib.splitString ", ";

  #--------------------------------------------------------------------#
  #-- Animation Settings
  #--------------------------------------------------------------------#
  # Kept in the hyprlang shorthand and converted to hl.curve / hl.animation below.
  animationSettings = {
    #--- Bezier Curves ("name, x1, y1, x2, y2")
    bezier = [
      #--- @End4 Design System
      "expressiveFastSpatial, 0.42, 1.67, 0.21, 0.90"
      "expressiveSlowSpatial, 0.39, 1.29, 0.35, 0.98"
      "expressiveDefaultSpatial, 0.38, 1.21, 0.22, 1.00"
      "emphasizedDecel, 0.05, 0.7, 0.1, 1"
      "emphasizedAccel, 0.3, 0, 0.8, 0.15"
      "standardDecel, 0, 0, 0, 1"
      "menu_decel, 0.1, 1, 0, 1"
      "menu_accel, 0.52, 0.03, 0.72, 0.08"
    ];

    #--- Animations ("leaf, enabled, speed, curve[, style]")
    animation = [
      #--- @End4 Design System
      "windowsIn, 1, 3, emphasizedDecel, popin 80%"
      "windowsOut, 1, 2, emphasizedDecel, popin 90%"
      "windowsMove, 1, 3, emphasizedDecel, slide"
      "border, 1, 10, emphasizedDecel"

      #--- layers
      "layersIn, 1, 2.7, emphasizedDecel, popin 93%"
      "layersOut, 1, 2.4, menu_accel, popin 94%"

      #--- fade
      "fadeLayersIn, 1, 0.5, menu_decel"
      "fadeLayersOut, 1, 2.7, menu_accel"

      #--- workspaces
      "workspaces, 1, 7, menu_decel, slidevert"

      #--- specialWorkspace
      "specialWorkspaceIn, 1, 2.8, emphasizedDecel, slidevert"
      "specialWorkspaceOut, 1, 1.2, emphasizedAccel, slidevert"
    ];
  };
in {
  wayland.windowManager.hyprland.settings = {
    config.animations.enabled = true;

    curve =
      map (s: let
        p = fields s;
      in {
        _args = [
          (elemAt p 0)
          {
            type = "bezier";
            points = [
              [(fromJSON (elemAt p 1)) (fromJSON (elemAt p 2))]
              [(fromJSON (elemAt p 3)) (fromJSON (elemAt p 4))]
            ];
          }
        ];
      })
      animationSettings.bezier;

    animation = map (s: let
      p = fields s;
    in
      {
        leaf = elemAt p 0;
        enabled = elemAt p 1 == "1";
        speed = fromJSON (elemAt p 2);
        bezier = elemAt p 3;
      }
      // lib.optionalAttrs (builtins.length p > 4) {style = elemAt p 4;})
    animationSettings.animation;
  };
}
