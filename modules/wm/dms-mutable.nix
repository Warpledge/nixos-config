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

  # live file | jq --slurpfile old <last applied> --slurpfile new <declared>
  merge = pkgs.writeText "dms-merge.jq" ''
    # Leaf paths; arrays and empty objects count as one value
    def leafpaths:
      if type == "object" and length > 0
      then to_entries[] | [.key] + (.value | leafpaths)
      else [] end;
    def get($p): try getpath($p) catch null;
    def has_path($p):
      try (getpath($p[:-1]) | type == "object" and has($p[-1])) catch false;
    def is_locked($p): any($locked[]; . as $l | $p[:($l | length)] == $l);
    $old[0] as $o | $new[0] as $n
    # The repo's value when locked, missing here, or never changed in the GUI
    | reduce ($n | leafpaths) as $p (.;
        if is_locked($p) or (has_path($p) | not)
          or (($o | has_path($p)) and get($p) == ($o | get($p)))
        then setpath($p; $n | get($p)) else . end)
    # Dropped from the repo and never changed in the GUI: drop it here too
    | reduce ($o | leafpaths) as $p (.;
        if ((($n | has_path($p)) or is_locked($p)) | not)
          and get($p) == ($o | get($p))
        then delpaths([$p]) else . end)
  '';
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
