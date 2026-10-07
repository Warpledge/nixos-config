#=====================================================================#
# LAYER RULES - BLUR & EFFECTS
#=====================================================================#
[
  #--- Blur: Core (GTK & Generic)
  "match:namespace gtk-layer-shell, blur on, ignore_alpha 0"
  "match:namespace launcher, blur on, ignore_alpha 0.85"

  #--- Blur: System UI (basic)
  "match:namespace session, blur on"
  "match:namespace bar, blur on, ignore_alpha 0.85"
  "match:namespace dock, blur on, ignore_alpha 0.85"
  "match:namespace ^indicator.*, blur on, ignore_alpha 0.85"
  "match:namespace overview, blur on, ignore_alpha 0.85"
  "match:namespace cheatsheet, blur on, ignore_alpha 0.85"
  "match:namespace osk, blur on, ignore_alpha 0.85"
  "match:namespace notifications, blur on, ignore_alpha 0"
  "match:namespace logout_dialog, blur on"

  #--- Blur: System utilities
  "match:namespace hyprlock, blur on, ignore_alpha 0"

  #--- Blur: Noctalia Shell
  # quickshell (background, full-screen container) intentionally no blur — specific quickshell:* components have their own rules
  # "match:namespace ^quickshell$, blur on, ignore_alpha 0.85"
  "match:namespace noctalia-bar, blur on, ignore_alpha 0.85"
  "match:namespace ^noctalia-bar-content.*, blur on, ignore_alpha 0.85"
  "match:namespace ^noctalia-background.*, blur on, ignore_alpha 0.85"
  "match:namespace quickshell-corner, blur on, ignore_alpha 0.85"

  #--- Blur & Animations: Quickshell UI (General)
  "match:namespace ^quickshell:.*, blur_popups on"
  "match:namespace ^quickshell:.*, blur on, ignore_alpha 0.79"

  #--- Blur & Animations: Session
  "match:namespace quickshell:session, blur on, ignore_alpha 0"

  #--- Xray (transparency effect)
  "match:namespace .*, xray on"
]
