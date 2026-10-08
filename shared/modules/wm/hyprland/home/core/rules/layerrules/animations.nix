#=====================================================================#
# LAYER RULES - ANIMATIONS
#=====================================================================#
[
  "match:namespace gtk4-layer-shell, animation off"
  "match:namespace launcher, animation off"
  "match:namespace selection, animation off"
  "match:namespace ^indicator.*, animation off"
  "match:namespace osk, animation off"
  "match:namespace noanim, animation off"
  "match:namespace quickshell:crosshair, animation off"
  "match:namespace quickshell:lockWindowPusher, animation off"
  "match:namespace quickshell:overview, animation off"
  "match:namespace quickshell:regionSelector, animation off"
  "match:namespace quickshell:screenshot, animation off"
  "match:namespace quickshell:session, animation off"

  #--- Animations: Quickshell UI
  "match:namespace quickshell:bar, animation slide"
  "match:namespace quickshell:cheatsheet, animation \"slide bottom\""
  "match:namespace quickshell:dock, animation \"slide bottom\""
  "match:namespace quickshell:screenCorners, animation \"popin 120%\""
  "match:namespace quickshell:notificationPopup, animation fade"
  "match:namespace quickshell:osk, animation \"slide bottom\""
  "match:namespace quickshell:sidebarRight, animation \"slide right\""
  "match:namespace quickshell:sidebarLeft, animation \"slide left\""
  "match:namespace quickshell:verticalBar, animation slide"
  "match:namespace quickshell:wallpaperSelector, animation \"slide top\""

  #--- Animations: Layout
  "match:namespace ^sideleft.*, animation \"slide top\""
  "match:namespace ^sideright.*, animation \"slide top\""
]
