#=====================================================================#
# PI - MINIMAL TERMINAL CODING AGENT
#=====================================================================#
#- Defaults to llama-swap's first coding model (its models.json is written by
#- llama-swap.nix), with the shared MCP servers and a matugen theme.
{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  dir = "${config.home.homeDirectory}/.pi/agent";

  #--- A server whose key is a file (mcp.nix) gets a wrapper that reads it at
  #--- launch, so the key stays out of the store
  wrap = name: s: let
    files = lib.filterAttrs (_: v: lib.isAttrs v && v ? file) s.env;
  in
    if files == {}
    then {inherit (s) command args;}
    else {
      command = "${pkgs.writeShellScript "pi-mcp-${name}" ''
        ${lib.concatStrings (lib.mapAttrsToList (var: v: ''
            ${var}=$(cat ${lib.escapeShellArg v.file}) && export ${var}
          '')
          files)}
        exec ${lib.escapeShellArgs ([s.command] ++ s.args)}
      ''}";
      args = [];
    };

  #--- The servers on in claude.mcp, minus GitHub: as in opencode.nix, its tool
  #--- schemas fill a local model's context, and `gh` does the job
  servers = lib.mapAttrs (name: s:
    if s.url != null
    then {inherit (s) url;}
    else wrap name s)
  (removeAttrs config.programs.mcp.servers ["github"]);

  #--- What the repo sets; mutable-merge.jq keeps what Pi itself writes
  declared = {
    "settings.json" =
      {theme = "dank";}
      // lib.optionalAttrs (user.llamaSwap.enable && user.localAi.code != []) {
        defaultProvider = "llama-swap";
        defaultModel = lib.head user.localAi.code;
      };
    "mcp.json".mcpServers = servers;
  };
in {
  home.packages = [pkgs.pi-coding-agent];

  #--- Pi hot-reloads its active theme from this file
  matugen.templates.pi = {
    input = ../../../theme/matugen/pi.json;
    output = "${dir}/themes/dank.json";
  };

  #--- Merged the way claude.nix merges settings.json: the rest of each file
  #--- and changes made in Pi stay until the repo changes the same key
  home.activation.piSettings = lib.hm.dag.entryAfter ["writeBoundary"] (let
    jq = lib.getExe pkgs.jq;
  in
    lib.concatStrings (lib.mapAttrsToList (file: value: ''
        settings_file="${dir}/${file}"
        declarative_file="${dir}/declarative-${file}"
        new_file=${pkgs.writeText "pi-declarative-${file}" (builtins.toJSON value)}
        if [[ -v DRY_RUN ]]; then
          echo "Would merge $new_file into $settings_file"
        else
          mkdir -p "${dir}"
          if ! ${jq} -e . "$settings_file" > /dev/null 2>&1; then
            cp --no-preserve=mode "$new_file" "$settings_file"
          else
            ${jq} -e . "$declarative_file" > /dev/null 2>&1 \
              || echo '{}' > "$declarative_file"
            merged="$(${jq} --slurpfile old "$declarative_file" \
              --slurpfile new "$new_file" --argjson locked '[]' \
              -f ${../../../../lib/mutable-merge.jq} "$settings_file")"
            printf '%s\n' "$merged" > "$settings_file"
          fi
          cp --no-preserve=mode "$new_file" "$declarative_file"
        fi
      '')
      declared));
}
