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
  #--- The coding and chat models turned on, by ID; the first coding one is the default
  codes = lib.genAttrs user.localAi.code (id: catalog.code.${id});
  chats = lib.genAttrs user.localAi.chat (id: catalog.chat.${id});
  edit =
    if user.localAi.edit == null
    then null
    else catalog.edit.${user.localAi.edit};
  defaultId = lib.head user.localAi.code;
  defaultFast = codes.${defaultId}.fast != null;

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
      lib.concatMapAttrs serve (codes // chats)
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
      #--- The coding and chat models don't fit the GPU together: one at a time
      lib.optionalAttrs (codes // chats != {}) {
        gpu = {
          swap = true;
          exclusive = false;
          members = lib.attrNames (codes // chats);
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
  home.file.".pi/agent/models.json" = lib.mkIf (user.pi.enable && codes != {}) {
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
              maxTokens = 32768;
            }
          ]
          ++ lib.optional (model.fast != null) {
            id = "${id}-instruct";
            name = "${model.name} (fast)";
            reasoning = false;
            contextWindow = model.context;
            maxTokens = 8192;
          })
        codes);
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- OpenCode Provider
  #--------------------------------------------------------------------#
  #--- Every coding model and its fast variant to pick from; the first is the default
  programs.opencode.settings = lib.mkIf (user.opencode.enable && codes != {}) {
    model = "llama-swap/${defaultId}";
    # Session titles and summaries: thinking there only delays the first reply
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
              output = 32768;
            };
          };
        }
        // lib.optionalAttrs (model.fast != null) {
          "${id}-instruct" = {
            name = "${model.name} (fast)";
            limit = {
              inherit (model) context;
              output = 8192;
            };
          };
        })
      codes;
    };
  };
}
