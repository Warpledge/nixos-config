#=====================================================================#
# WINDOW RULES - FLOATING, CENTERING, SIZING
#=====================================================================#
[
  #--- Floating: Tag-based modals
  "match:tag modal, float on"
  "match:tag modal, center on"

  #--- Floating: Media Viewers
  "match:class ^(Viewnior)$, float on"
  "match:class ^(imv)$, float on"
  "match:class ^(mpv)$, float on"
  "match:class ^(mpv)$, idle_inhibit focus"

  #--- Floating: File Management
  "match:class ^(org.gnome.FileRoller)$, float on"
  "match:class ^(file_progress)$, float on"
  "match:title ^(File Upload)$, float on"
  "match:title ^(File Operation Progress)$, float on"

  #--- Floating: Audio & System
  "match:class ^(org.pulseaudio.pavucontrol)$, float on"
  "match:class ^(SoundWireServer)$, float on"
  "match:title ^(Volume Control)$, float on"
  "match:class ^(nm-connection-editor)$, float on"

  #--- Floating: File Dialogs
  "match:title ^(Open File)$, float on"
  "match:title ^(Select a File)$, float on"
  "match:title ^(Save As)$, float on"
  "match:title ^(Open Folder)$, float on"
  "match:title ^(Choose wallpaper)$, float on"
  "match:title ^(branchdialog)$, float on"
  "match:title ^(Confirm to replace files)$, float on"
  "match:title ^(File Upload)(.*)$, float on"
  "match:title ^(.*)(wants to save)$, float on"
  "match:title ^(.*)(wants to open)$, float on"

  #--- Floating: Generic Dialogs
  "match:class ^(confirm)$, float on"
  "match:class ^(dialog)$, float on"
  "match:class ^(download)$, float on"
  "match:class ^(notification)$, float on"
  "match:class ^(error)$, float on"
  "match:class ^(confirmreset)$, float on"

  #--- Floating: Utilities
  "match:class ^(org.gnome.Calculator)$, float on"
  "match:class ^(waypaper)$, float on"
  "match:class ^(zenity)$, float on"
  "match:class ^(org.gnome.Loupe)$, float on"
  "match:class ^(io.github.alainm23.planify)$, float on"
  "match:class ^(io.github.celluloid_player.Celluloid)$, float on"
  "match:class ^(Audacious)$, float on"
  "match:class ^(.sameboy-wrapped)$, float on"
  "match:title ^(Transmission)$, float on"
  "match:title ^(Firefox — Sharing Indicator)$, float on"

  #--- Centering: File Dialogs
  "match:title ^(Open File)(.*)$, center on"
  "match:title ^(Select a File)(.*)$, center on"
  "match:title ^(Choose wallpaper)(.*)$, center on"
  "match:title ^(Open Folder)(.*)$, center on"
  "match:title ^(Save As)(.*)$, center on"
  "match:title ^(Library)(.*)$, center on"
  "match:title ^(File Upload)(.*)$, center on"
  "match:title ^(.*)(wants to save)$, center on"
  "match:title ^(.*)(wants to open)$, center on"
  "match:class ^(org.pulseaudio.pavucontrol)$, center on"
  "match:class ^(nm-connection-editor)$, center on"

  #--- Sizing: Dialog windows
  "match:title ^(Choose wallpaper)(.*)$, size 60% 65%"
  "match:class ^(zenity)$, size 850 500"

  #--- Sizing: Application windows
  "match:class ^(org.pulseaudio.pavucontrol)$, size 45% 45%"
  "match:class ^(nm-connection-editor)$, size 45% 45%"
  "match:title ^(Volume Control)$, size 700 450"
  "match:class ^(io.github.alainm23.planify)$, size 900 700"
  "match:class ^(io.github.celluloid_player.Celluloid)$, size 1280 720"
]
