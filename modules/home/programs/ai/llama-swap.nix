#=====================================================================#
# LLAMA-SWAP - LOCAL LLM SERVER (LLAMA.CPP, VULKAN)
#=====================================================================#
#- Serves the models picked in localAi (lib/local-models.nix lists them)
#- and makes them opencode's and Zed's defaults.
{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  port = 8090; # 8080 is taken by Steam's webhelper
  catalog = import ../../../../lib/local-models.nix;
  pick = kind: name:
    if name == null
    then null
    else catalog.${kind}.${name};
  code = pick "code" user.localAi.code;
  edit = pick "edit" user.localAi.edit;
  codeId = user.localAi.code;
  fastId = "${codeId}-instruct";
  hasFast = code != null && code.fast != null;

  #--- Finds the model's file in its LM Studio folder, so the exact name and case
  #--- of a download don't matter; the first part of a split file sorts first
  launch = pkgs.writeShellScript "llama-model" ''
    dir="${config.home.homeDirectory}/.lmstudio/models/$1" match=$2
    shift 2
    file=$(find "$dir" -maxdepth 1 -iname "$match" 2>/dev/null | sort | head -n 1)
    if [ -z "$file" ]; then
      echo "No $match in $dir: download it in LM Studio" >&2
      exit 1
    fi
    exec ${lib.getExe' pkgs.llama-cpp-vulkan "llama-server"} -m "$file" "$@"
  '';
  cmd = model: args: lib.concatStringsSep " " ([launch "'${model.dir}'" "'${model.match}'" "--port \${PORT}"] ++ args);

  #--- One slot gets the whole context; q8_0 cache halves its VRAM
  codeCmd = temp: extra:
    cmd code (["-c ${toString code.context}" "-np 1" "-fa on" "-ctk q8_0" "-ctv q8_0" "--no-webui"]
      ++ code.args
      ++ ["--temp ${toString temp}"]
      ++ extra);

  #--- Loads on the first request, unloads after `ttl` idle seconds to free VRAM
  settings = {
    models =
      lib.optionalAttrs (code != null) {
        ${codeId} = {
          ttl = 600;
          cmd = codeCmd code.temp code.think;
        };
      }
      // lib.optionalAttrs hasFast {
        ${fastId} = {
          ttl = 600;
          cmd = codeCmd code.fastTemp code.fast;
        };
      }
      // lib.optionalAttrs (edit != null) {
        ${user.localAi.edit} = {
          ttl = 600;
          cmd = cmd edit [
            # CPU only: -ngl 0 alone still allocates GPU buffers
            "--device none"
            "-c ${toString edit.context}"
            "--cache-reuse 256" # Reuses the cached prompt between keystrokes
            "-np 1"
            "-fa on"
            "--no-webui"
          ];
        };
      };
    #--- One coding variant at a time; switching reloads it (from page cache)
    groups =
      lib.optionalAttrs (code != null) {
        chat = {
          swap = true;
          exclusive = false;
          members = [codeId] ++ lib.optional hasFast fastId;
        };
      }
      #--- Stays loaded beside either variant
      // lib.optionalAttrs (edit != null) {
        predict = {
          swap = false;
          exclusive = false;
          persistent = true;
          members = [user.localAi.edit];
        };
      };
  };
  configFile = (pkgs.formats.yaml {}).generate "llama-swap.yaml" settings;
in {
  #--------------------------------------------------------------------#
  #-- Service
  #--------------------------------------------------------------------#
  systemd.user.services.llama-swap = {
    Unit.Description = "llama-swap local LLM server";
    Install.WantedBy = ["default.target"];
    Service = {
      ExecStart = "${lib.getExe pkgs.llama-swap} -listen 127.0.0.1:${toString port} -config ${configFile}";
      Restart = "on-failure";
    };
  };

  #--------------------------------------------------------------------#
  #-- OpenCode Provider
  #--------------------------------------------------------------------#
  programs.opencode.settings = lib.mkIf (user.opencode.enable && code != null) {
    model = "llama-swap/${codeId}";
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options.baseURL = "http://127.0.0.1:${toString port}/v1";
      models =
        {
          ${codeId} = {
            inherit (code) name;
            limit = {
              inherit (code) context;
              output = 16384; # Thinking tokens count against it
            };
          };
        }
        // lib.optionalAttrs hasFast {
          ${fastId} = {
            name = "${code.name} (fast)";
            limit = {
              inherit (code) context;
              output = 8192;
            };
          };
        };
    };
  };
}
