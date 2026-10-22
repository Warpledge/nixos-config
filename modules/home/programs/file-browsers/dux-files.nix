#=====================================================================#
# DUX FILES (DUX-FILES) FILE BROWSER CONFIGURATION
#=====================================================================#
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  dir = "${config.xdg.configHome}/dfiles";
  state = "${config.xdg.stateHome}/dfiles-declared";
  jq = lib.getExe pkgs.jq;

  # Only values that differ from upstream's (quickshell/Common/SettingsData.qml);
  # theme, colours and fonts are left to the app (rule 5)
  settings = pkgs.writeText "dfiles-ui-settings.json" (builtins.toJSON {
    confirmTrash = true;
    defaultView = "list";
    focusRingEnabled = false;
    recentFiles = false;
    showHidden = true;
  });

  bookmark = path: label: {
    path = "${config.home.homeDirectory}/${path}";
    inherit label;
    icon = "";
  };
  bookmarks = pkgs.writeText "dfiles-bookmarks.json" (builtins.toJSON {
    version = 2;
    bookmarks = [
      (bookmark "Downloads" "Downloads")
      (bookmark "Documents" "Documents")
      (bookmark "Pictures" "Pictures")
      (bookmark "Videos" "Videos")
      (bookmark "Games" "Games")
      (bookmark ".local/share" "Local")
      (bookmark ".local/share/Steam/steamapps/common" "Steam")
      (bookmark ".local/share/Terraria/tModLoader" "tModLoader")
      {
        path = "trash:///";
        label = "Trash";
        icon = "";
      }
    ];
  });
in {
  #--------------------------------------------------------------------#
  #-- Packages & Modules
  #--------------------------------------------------------------------#

  imports = [
    inputs.dux-files.homeModules.dux-files
  ];

  # settings is left unset: upstream writes it as a read-only store link
  programs.dux-files = {
    enable = true;
    systemd.enable = true; # Resident instance, so windows open fast
  };

  #--------------------------------------------------------------------#
  #-- Settings & Bookmarks
  #--------------------------------------------------------------------#
  # Real files the app can save to. A setting changed in the app survives
  # rebuilds (lib/mutable-merge.jq); bookmarks are seeded once.

  home.activation.dfilesMutableFiles = lib.hm.dag.entryAfter ["linkGeneration"] ''
    f="${dir}/ui-settings.json"
    old="${state}/ui-settings.json"
    b="${dir}/bookmarks.json"
    if [[ -v DRY_RUN ]]; then
      echo "Would merge ${settings} into $f"
    else
      mkdir -p "${dir}" "${state}"
      # The read-only links an older generation left
      [[ -L "$f" ]] && rm -f "$f"
      [[ -L "$b" ]] && rm -f "$b"
      [[ -s "$f" ]] && ${jq} empty "$f" 2>/dev/null || echo '{}' > "$f"
      [[ -s "$old" ]] || echo '{}' > "$old"
      merged="$(${jq} --slurpfile old "$old" --slurpfile new ${settings} \
        --argjson locked '[]' -f ${../../../../lib/mutable-merge.jq} "$f")"
      printf '%s\n' "$merged" > "$f"
      cp --no-preserve=mode ${settings} "$old"
      [[ -e "$b" ]] || cp --no-preserve=mode ${bookmarks} "$b"
    fi
  '';
}
