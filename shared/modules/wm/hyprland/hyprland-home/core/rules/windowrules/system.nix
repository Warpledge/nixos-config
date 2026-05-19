#=====================================================================#
# WINDOW RULES - SYSTEM-LEVEL
#=====================================================================#
[
  #--- xWaylandvideo bridge (screen share)
  "match:class ^(xwaylandvideobridge)$, opacity 0.0 override"
  "match:class ^(xwaylandvideobridge)$, animation off"
  "match:class ^(xwaylandvideobridge)$, no_initial_focus on"
  "match:class ^(xwaylandvideobridge)$, max_size 1 1"
  "match:class ^(xwaylandvideobridge)$, no_blur on"

  #--- Chromium context menus (remove transparency)
  "match:class ^()$, match:title ^()$, opaque on"
  "match:class ^()$, match:title ^()$, no_shadow on"
  "match:class ^()$, match:title ^()$, no_blur on"

  #--- Window styling
  "match:float 0, no_shadow on"
]
