#=====================================================================#
# CLAUDE DESKTOP - ANTHROPIC'S DESKTOP APP (CHAT, CODE)
#=====================================================================#
#- Anthropic's official Linux .deb, patched by the claude-desktop input.
#- The Code tab downloads its own Claude Code binary, which runs through
#- nix-ld (nixos/services/runtimes/runners.nix).
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  #--- Chat's config file takes local servers only; remote ones are added as
  #--- connectors in the app. Token files are read by a wrapper at launch.
  declared.mcpServers = lib.mapAttrs (name: server:
    lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = ["enabled"];
      extraTransforms = [(lib.hm.mcp.wrapEnvFilesCommand {inherit pkgs name;})];
    })
  (lib.filterAttrs (_: s: (s.url or null) == null) config.programs.mcp.servers);
  # Cowork's VM needs system-side firmware paths and the kvm group
  claude-desktop =
    (pkgs.callPackage "${inputs.claude-desktop}/package.nix" {withCowork = false;})
    .overrideAttrs (old: {
      # Launch by name so the Mullvad split-tunnel wrapper on PATH applies
      postFixup =
        old.postFixup
        + ''
          sed -i 's|^Exec=[^ ]*|Exec=claude-desktop|' $out/share/applications/*.desktop
        '';
    });
in {
  #--- Read by the Mullvad split tunnel (nixos/security/mullvad/split-tunnel.nix)
  options.claude-desktop.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "The Claude Desktop build in home.packages.";
  };

  config = {
    claude-desktop.package = claude-desktop;
    home.packages = [claude-desktop];

    #--- Merges `declared` like claude.nix does, so the app's own keys and servers
    #--- added in it stay; restart the app to load a change
    home.activation.claudeDesktopConfig = lib.hm.dag.entryAfter ["writeBoundary"] (let
      jq = lib.getExe pkgs.jq;
    in ''
      dir="${config.xdg.configHome}/Claude"
      declarative_file="$dir/declarative-config.json"
      config_file="$dir/claude_desktop_config.json"
      new_file=${pkgs.writeText "claude-desktop-declarative-config.json" (builtins.toJSON declared)}

      if [[ -v DRY_RUN ]]; then
        echo "Would merge $new_file into $config_file"
      else
        mkdir -p "$dir"
        if ! ${jq} -e . "$config_file" > /dev/null 2>&1; then
          cp --no-preserve=mode "$new_file" "$config_file"
        else
          ${jq} -e . "$declarative_file" > /dev/null 2>&1 \
            || echo '{}' > "$declarative_file"
          merged="$(${jq} --slurpfile old "$declarative_file" \
            --slurpfile new "$new_file" --argjson locked '[]' \
            -f ${../../../../lib/mutable-merge.jq} "$config_file")"
          printf '%s\n' "$merged" > "$config_file"
        fi
        cp --no-preserve=mode "$new_file" "$declarative_file"
      fi
    '');
  };
}
