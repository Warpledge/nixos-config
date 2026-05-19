#=====================================================================#
# WINDOW RULES - WAYDROID (Android Container)
#=====================================================================#
[
  #--- Waydroid: Main window
  "match:class ^(Waydroid)$, workspace 3"
  "match:class ^(Waydroid)$, float off"
  "match:class ^(Waydroid)$, fullscreen 1"

  #--- Waydroid: Dialogs and overlays
  "match:class ^(Waydroid)$, match:title ^((?!Waydroid).*), float on"
]
