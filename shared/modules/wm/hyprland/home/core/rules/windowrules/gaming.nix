#=====================================================================#
# WINDOW RULES - GAMING
#=====================================================================#
[
  #--- Gamescope
  "match:class ^(gamescope)$, float on"
  "match:class ^(gamescope)$, center on"
  "match:class ^(gamescope)$, fullscreen on"
  "match:class ^(gamescope)$, immediate on"

  #--- Steam's secondary windows (Friends List, Settings, game properties);
  #--- the main library stays tiled
  "match:class ^(steam)$, match:title negative:^(Steam)$, float on"

  #--- Minecraft
  "match:class ^Minecraft.*, fullscreen on"

  #--- Game performance (immediate removed: white flash on AMD with direct
  #--- scanout)
  #--- Tiling (non-floating)
  "match:class ^dev\.warp\.Warp$, tile on"
]
