{
  config,
  lib,
  pkgs,
  ...
}: let
  dir = "${config.xdg.configHome}/DankMaterialShell";
  state = "${config.xdg.stateHome}/dms-declared";
  jq = lib.getExe pkgs.jq;
  locked = builtins.toJSON config.dms.lockedSettings;

  merge = ../../lib/mutable-merge.jq;
in {
  #====================================================================#
  # DMS SETTINGS THE GUI CAN SAVE
  #====================================================================#
  options.dms = {
    mutableFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = "Declared JSON per file name in ~/.config/DankMaterialShell.";
    };
    lockedSettings = lib.mkOption {
      type = lib.types.listOf (lib.types.listOf lib.types.str);
      description = "Key paths the repo resets on every rebuild; a path locks its subkeys.";
    };
    writableFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Files under ~/.config that DMS writes, created empty if missing.";
    };
  };

  #--------------------------------------------------------------------#
  #-- Locked Settings
  #--------------------------------------------------------------------#
  #- Theme, fonts and cursor come from Stylix and catppuccin/nix (rule 5)
  config.dms.lockedSettings = [
    ["currentThemeName"]
    ["currentThemeCategory"]
    ["customThemeFile"]
    ["fontFamily"]
    ["monoFontFamily"]
    ["cursorSettings" "theme"]
    ["cursorSettings" "size"]
    ["matugenTemplateNeovim"]
  ];

  #--------------------------------------------------------------------#
  #-- Merge
  #--------------------------------------------------------------------#
  # Written as real files, not store links, so the settings GUI can save.
  # A key changed in the GUI stays; locked keys are reset on every rebuild.
  config.home.activation.dmsMutableFiles = lib.hm.dag.entryAfter ["linkGeneration"] (
    lib.concatStrings (lib.mapAttrsToList (name: declared: ''
        f="${dir}/${name}"
        old="${state}/${name}"
        if [[ -v DRY_RUN ]]; then
          echo "Would merge ${declared} into $f"
        else
          mkdir -p "${dir}" "${state}"
          # The read-only link an older generation left
          [[ -L "$f" ]] && rm -f "$f"
          [[ -s "$f" ]] && ${jq} empty "$f" 2>/dev/null || echo '{}' > "$f"
          [[ -s "$old" ]] || echo '{}' > "$old"
          merged="$(${jq} --slurpfile old "$old" --slurpfile new ${declared} \
            --argjson locked '${locked}' -f ${merge} "$f")"
          printf '%s\n' "$merged" > "$f"
          cp --no-preserve=mode ${declared} "$old"
        fi
      '')
      config.dms.mutableFiles)
    + lib.concatMapStrings (path: ''
      f="${config.xdg.configHome}/${path}"
      if [[ ! -v DRY_RUN ]]; then
        [[ -L "$f" ]] && rm -f "$f"
        mkdir -p "$(dirname "$f")"
        [[ -e "$f" ]] || : > "$f"
      fi
    '')
    config.dms.writableFiles
  );
}
