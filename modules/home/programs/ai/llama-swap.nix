#=====================================================================#
# LLAMA-SWAP - LOCAL LLM SERVER (LLAMA.CPP, VULKAN OR CUDA)
#=====================================================================#
#- Serves the models picked in localAi (lib/local-ai.nix gives this
#- machine's models and flags) and makes them opencode's and Zed's defaults.
{
  config,
  lib,
  pkgs,
  machine,
  user,
  ...
}: let
  port = 8090; # 8080 is taken by Steam's webhelper
  catalog = import ../../../../lib/local-ai.nix {
    inherit lib;
    inherit (machine) localModels;
  };
  #--- The models turned on, by ID; every harness lists all of them
  enabled = lib.genAttrs user.localAi.models (id: catalog.models.${id});
  edit =
    if user.localAi.edit == null
    then null
    else catalog.edit.${user.localAi.edit};
  defaultId = user.localAi.default;
  defaultFast = enabled.${defaultId}.fast != null;
  #--- At most half the context, so a 32K model doesn't reserve it all for output
  outputLimit = limit: model: lib.min limit (model.context / 2);

  #--- Finds the model's file in its LM Studio folder, so the exact name and case
  #--- of a download don't matter; the first part of a split file sorts first
  #--- The third argument is the vision projector's match in the same folder, or -;
  #--- the fourth is the MTP file's, loaded as a draft model
  launch = pkgs.writeShellScript "llama-model" ''
    dir="${config.home.homeDirectory}/.lmstudio/models/$1" match=$2 vision=$3 mtp=$4
    shift 4
    file=$(find "$dir" -maxdepth 1 -iname "$match" 2>/dev/null | sort | head -n 1)
    if [ -z "$file" ]; then
      echo "No $match in $dir: download it in LM Studio" >&2
      exit 1
    fi
    if [ "$vision" != - ]; then
      proj=$(find "$dir" -maxdepth 1 -iname "$vision" 2>/dev/null | sort | head -n 1)
      if [ -z "$proj" ]; then
        echo "No $vision in $dir: download the vision file in LM Studio" >&2
        exit 1
      fi
      set -- --mmproj "$proj" "$@"
    fi
    if [ "$mtp" != - ]; then
      draft=$(find "$dir" -maxdepth 1 -iname "$mtp" 2>/dev/null | sort | head -n 1)
      if [ -z "$draft" ]; then
        echo "No $mtp in $dir: download the MTP file in LM Studio" >&2
        exit 1
      fi
      set -- -md "$draft" --spec-type draft-mtp "$@"
    fi
    exec ${lib.getExe' (catalog.llamaCpp pkgs) "llama-server"} -m "$file" "$@"
  '';
  cmd = model: args:
    lib.concatStringsSep " " ([launch "'${model.dir}'" "'${model.match}'" "'${model.mmproj or "-"}'" "'${model.mtp or "-"}'" "--port \${PORT}"]
      ++ args);

  #--- A coding or chat model. One slot gets the whole context; a q8_0 cache halves
  #--- its VRAM unless the model sets `cache`. Each ID gets its variant's sampling over
  #--- whatever the client sent;
  #--- the -instruct and -chat keys also register as aliases, so they need no reload
  serve = id: model: {
    ${id} = {
      ttl = 600;
      cmd =
        cmd model (["-c ${toString model.context}" "-np 1" "-fa on" "-ctk ${model.cache or "q8_0"}" "-ctv ${model.cache or "q8_0"}" "--no-webui"]
          ++ model.args);
      filters.setParamsByID =
        {${id} = model.think;}
        // lib.optionalAttrs (model.fast != null) {"${id}-instruct" = model.fast;}
        // lib.optionalAttrs (model.chat or null != null) {"${id}-chat" = model.chat;};
    };
  };

  #--- Loads on the first request, unloads after `ttl` idle seconds to free VRAM
  settings = {
    # Lists the -instruct and -chat aliases in /v1/models, so Open WebUI shows them
    includeAliasesInList = true;
    models =
      lib.concatMapAttrs serve enabled
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
    groups =
      #--- The models don't fit the GPU together: one at a time
      lib.optionalAttrs (enabled != {}) {
        gpu = {
          swap = true;
          exclusive = false;
          members = lib.attrNames enabled;
        };
      }
      #--- Stays loaded beside them
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
  #-- Pi Provider
  #--------------------------------------------------------------------#
  #--- The same models as opencode's; Pi reloads the file when /model opens
  home.file.".pi/agent/models.json" = lib.mkIf (user.pi.enable && enabled != {}) {
    text = builtins.toJSON {
      "$schema" = "https://pi.dev/schemas/models.schema.json";
      providers.llama-swap = {
        name = "llama-swap (local)";
        baseUrl = "http://127.0.0.1:${toString port}/v1";
        api = "openai-completions";
        apiKey = "llama-swap"; # Unused, but Pi lists a provider only with one
        # llama.cpp's chat templates know no developer role or reasoning_effort
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
        models = lib.concatLists (lib.mapAttrsToList (id: model:
          [
            {
              inherit id;
              inherit (model) name;
              reasoning = true;
              contextWindow = model.context;
              maxTokens = outputLimit 32768 model;
            }
          ]
          ++ lib.optional (model.fast != null) {
            id = "${id}-instruct";
            name = "${model.name} (fast)";
            reasoning = false;
            contextWindow = model.context;
            maxTokens = outputLimit 8192 model;
          })
        enabled);
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- OpenCode Provider
  #--------------------------------------------------------------------#
  #--- Every model turned on and its fast variant to pick from
  programs.opencode.settings = lib.mkIf (user.opencode.enable && enabled != {}) {
    model = "llama-swap/${defaultId}";
    # OpenCode's title agent: thinking there only delays the first reply
    small_model = "llama-swap/${defaultId}${lib.optionalString defaultFast "-instruct"}";
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options.baseURL = "http://127.0.0.1:${toString port}/v1";
      models = lib.concatMapAttrs (id: model:
        {
          ${id} = {
            inherit (model) name;
            limit = {
              inherit (model) context;
              # Qwen's recommended output length; thinking tokens count against it
              output = outputLimit 32768 model;
            };
          };
        }
        // lib.optionalAttrs (model.fast != null) {
          "${id}-instruct" = {
            name = "${model.name} (fast)";
            limit = {
              inherit (model) context;
              output = outputLimit 8192 model;
            };
          };
        })
      enabled;
    };
  };
}
