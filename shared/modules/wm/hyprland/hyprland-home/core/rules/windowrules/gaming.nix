#=====================================================================#
# WINDOW RULES - GAMING
#=====================================================================#
[
  #--- Gamescope
  "match:class ^(gamescope)$, float on"
  "match:class ^(gamescope)$, center on"
  "match:class ^(gamescope)$, fullscreen on"
  "match:class ^(gamescope)$, immediate on"

  #--- Game performance (immediate removed — caused white flash on AMD with direct scanout)
  #--- Tiling (non-floating)
  "match:class ^dev\.warp\.Warp$, tile on"
]
