#=====================================================================#
# TML-PRELAUNCH - TMODLOADER PRE-LAUNCH PATCH SCRIPT
#=====================================================================#
#- Patches tModLoader.runtimeconfig.json with recommended performance
#- and stability settings before each launch. Survives tModLoader updates
#- since the file is re-patched on every launch via Steam pre-launch.
#-
#- Patches applied:
#-   DEFAULT_STACK_SIZE: 51200000           (512MB stack, prevents overflow)
#-   System.GC.Server: true                 (multi-core GC)
#-   System.GC.Concurrent: true             (concurrent GC, reduces stutter)
#-   System.GC.HeapCount: 8                 (one heap per core, 5800X3D)
#-   System.GC.HeapAffinitizeMask: 255      (pin heaps to cores 0-7)
#-   MetadataUpdater.IsSupported: false     (disable hot reload overhead)
#-   EnableUnsafeBinaryFormatterSerialization: false
{pkgs, ...}: let
  tml-prelaunch =
    pkgs.writeShellScriptBin "tml-prelaunch"
    # bash
    ''
      RUNTIMECONFIG="$HOME/.local/share/Steam/steamapps/common/tModLoader/tModLoader.runtimeconfig.json"

      if [[ ! -f "$RUNTIMECONFIG" ]]; then
        echo "[tml-prelaunch] WARNING: $RUNTIMECONFIG not found, skipping patch"
      else
        PATCHED=$(${pkgs.jq}/bin/jq '
          .runtimeOptions.configProperties |= (. // {}) * {
            "DEFAULT_STACK_SIZE": "51200000",
            "System.Reflection.Metadata.MetadataUpdater.IsSupported": false,
            "System.Runtime.Serialization.EnableUnsafeBinaryFormatterSerialization": false,
            "System.GC.Server": true,
            "System.GC.Concurrent": true,
            "System.GC.HeapCount": 8,
            "System.GC.HeapAffinitizeMask": 255
          }
        ' "$RUNTIMECONFIG") && {
          echo "$PATCHED" > "$RUNTIMECONFIG"
          echo "[tml-prelaunch] Patched $RUNTIMECONFIG successfully"
        } || echo "[tml-prelaunch] ERROR: jq failed to parse $RUNTIMECONFIG, skipping patch"
      fi

      if [[ $# -gt 0 ]]; then
        export LD_PRELOAD=""
        exec "$@"
      fi
    '';
in {
  home.packages = [tml-prelaunch];
}
