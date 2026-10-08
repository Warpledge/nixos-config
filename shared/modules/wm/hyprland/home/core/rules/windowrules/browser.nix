#=====================================================================#
# WINDOW RULES - BROWSER-SPECIFIC
#=====================================================================#
[
  "match:class ^(firefox)$, idle_inhibit fullscreen"
  "match:class ^(.*google.*)$, stay_focused on"
  "match:title ^(.*[Ll]ogin.*)$, stay_focused on"
  "match:class ^(twintail)$, no_blur on"
  "match:class ^(helium)$, maximize on"
  # youtube-dispatch link handoffs stay in the background
  "match:class ^(freetube)$, no_initial_focus on"
]
