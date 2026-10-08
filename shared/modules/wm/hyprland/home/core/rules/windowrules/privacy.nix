#=====================================================================#
# WINDOW RULES - PRIVACY
#=====================================================================#
# Blocked from screenshots and screen recording; mirrors niri's block-out-from
# list in niri/home/core/rules.nix. Hyprland regexes are full-match.
let
  hide = "no_screen_share on";
in [
  "match:class ^(org\\.gnome\\.seahorse\\.Application)$, ${hide}"
  "match:class ^(bitwarden)$, ${hide}"
  "match:class ^(zen-beta)$, match:title ^Extension: \\(Bitwarden.*, ${hide}" # Bitwarden extension popup (Zen)
  "match:class ^(mullvad-vpn)$, ${hide}"
  "match:class ^(Mullvad Browser)$, ${hide}"
  "match:class ^(helium)$, ${hide}"
  "match:class ^(chrome-localhost__-Default)$, ${hide}" # Suwayomi (Helium app window)
  "match:class ^(chrome-127\\.0\\.0\\.1__-Default)$, ${hide}" # Seanime (Helium app window)
  "match:class ^(chrome-127\\.0\\.0\\.1__index\\.html-Default)$, ${hide}" # Syncthing (Helium app window)
  "match:class ^(moku)$, ${hide}"
  "match:class ^(boorusama)$, ${hide}"
  "match:class ^(thunderbird)$, ${hide}"
  "match:class ^(md\\.obsidian\\.Obsidian)$, ${hide}"
  "match:class ^(homebank)$, ${hide}"
  "match:class ^(vesktop)$, ${hide}"
]
