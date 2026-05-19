#=====================================================================#
# WINDOW RULES - OPACITY
#=====================================================================#
let
  opacityRule = "opacity 0.80 0.80 override";
in [
  "match:class ^(kitty)$, ${opacityRule}"
  "match:class ^(com.mitchellh.ghostty)$, ${opacityRule}"
  "match:class ^(dev.zed.Zed)$, ${opacityRule}"
  "match:class ^(org.gnome.Nautilus)$, ${opacityRule}"
  "match:class ^(org.gnome.FileRoller)$, ${opacityRule}"
  "match:class ^(org.kde.dolphin)$, ${opacityRule}"
  "match:class ^(thunar)$, ${opacityRule}"
  "match:title ^(Volume Control)$, ${opacityRule}"
  "match:class ^(org.pulseaudio.pavucontrol)$, ${opacityRule}"
  "match:class ^(pavucontrol)$, ${opacityRule}"
  "match:class ^(nm-connection-editor)$, ${opacityRule}"
  "match:class ^(org.gnome.Calculator)$, ${opacityRule}"
  "match:class ^(guifetch)$, ${opacityRule}"
  "match:class ^(blueberry.py)$, ${opacityRule}"
  "match:class ^(Zotero)$, ${opacityRule}"
  "match:class ^(io.github.alainm23.planify)$, ${opacityRule}"
  "match:class ^(file_progress)$, ${opacityRule}"
  "match:class ^(notification)$, ${opacityRule}"
  "match:class ^(download)$, ${opacityRule}"
  "match:class ^(confirm)$, ${opacityRule}"
  "match:class ^(dialog)$, ${opacityRule}"
  "match:class ^(error)$, ${opacityRule}"
  "match:class ^(confirmreset)$, ${opacityRule}"
  "match:title ^(Open File)$, ${opacityRule}"
  "match:title ^(File Upload)$, ${opacityRule}"
  "match:title ^(branchdialog)$, ${opacityRule}"
  "match:title ^(Confirm to replace files)$, ${opacityRule}"
  "match:class ^(org.quickshell)$, ${opacityRule}"
  "match:class ^(Revolt)$, ${opacityRule}"
  "match:class ^(Spotify)$, ${opacityRule}"
  "match:class ^(Root)$, ${opacityRule}"
  "match:class ^(org.prismlauncher.PrismLauncher)$, ${opacityRule}"
  # "match:class ^(zen-beta)$, ${opacityRule}" # Zen Browser
]
