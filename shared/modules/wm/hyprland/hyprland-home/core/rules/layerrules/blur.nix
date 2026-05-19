#=====================================================================#
# LAYER RULES - BLUR & EFFECTS
#=====================================================================#
[
  #--- Blur: Core (GTK & Generic)
  "match:namespace gtk-layer-shell, blur on ignorezero on"
  "match:namespace launcher, blur on ignorealpha 0.85"

  #--- Blur: System UI (basic)
  "match:namespace session, blur on"
  "match:namespace bar, blur on ignorealpha 0.85"
  "match:namespace dock, blur on ignorealpha 0.85"
  "match:namespace ^indicator.*, blur on ignorealpha 0.85"
  "match:namespace overview, blur on ignorealpha 0.85"
  "match:namespace cheatsheet, blur on ignorealpha 0.85"
  "match:namespace osk, blur on ignorealpha 0.85"
  "match:namespace notifications, blur on ignorezero on"
  "match:namespace logout_dialog, blur on"

  #--- Blur: System utilities
  "match:namespace hyprlock, blur on ignorezero on"


  #--- Blur: Noctalia Shell
  # quickshell (background, full-screen container) intentionally no blur — specific quickshell:* components have their own rules
  # "match:namespace ^quickshell$, blur on ignorealpha 0.85"
  "match:namespace noctalia-bar, blur on ignorealpha 0.85"
  "match:namespace ^noctalia-bar-content.*, blur on ignorealpha 0.85"
  "match:namespace ^noctalia-background.*, blur on ignorealpha 0.85"
  "match:namespace quickshell-corner, blur on ignorealpha 0.85"

  #--- Blur & Animations: Quickshell UI (General)
  "match:namespace ^quickshell:.*, blur_popups on"
  "match:namespace ^quickshell:.*, blur on ignorealpha 0.79"

  #--- Blur & Animations: Session
  "match:namespace quickshell:session, blur on ignorealpha 0"

  #--- Xray (transparency effect)
  "match:namespace .*, xray 1"
]
