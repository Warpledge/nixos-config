#=====================================================================#
# WINDOW RULES - PINNING & SPECIAL POSITIONING
#=====================================================================#
[
  #--- Pinning
  "match:tag modal, pin on"
  "match:class ^(rofi)$, pin on"
  "match:class ^(waypaper)$, pin on"
  "match:title ^(Picture-in-Picture)$, pin on"
  "match:title ^(Picture in picture)$, pin on"
  "match:title ^(Mullvad VPN)$, pin on"
  "match:title ^(Volume Control)$, pin on"
  "match:class ^(io.github.alainm23.planify)$, pin on"

  #--- Picture-in-Picture
  "match:title ^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$, float on"
  "match:title ^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$, keep_aspect_ratio on"
  "match:title ^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$, move 73% 72%"
  "match:title ^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$, size 25% 25%"
  "match:title ^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$, pin on"

  #--- Positioning
  "match:title ^(Firefox — Sharing Indicator)$, move 0 0"
]
