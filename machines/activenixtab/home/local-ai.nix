#=====================================================================#
# LOCAL AI (FLOW Z13)
#=====================================================================#
#- llama-swap on the Radeon 8060S with models sized for 128 GB of shared
#- memory, in place of the config's llamaSwap (tuned for a 16 GB card).
#- Open WebUI (openWebui.enable) reaches it on 127.0.0.1:8090.
{
  config,
  lib,
  pkgs,
  ...
}: let
  port = 8090; # Open WebUI's address for llama-swap

  #--- Finds a download in its LM Studio folder, whatever the file's exact name;
  #--- the first part of a split file sorts first
  launch = pkgs.writeShellScript "llama-model" ''
    dir="${config.home.homeDirectory}/.lmstudio/models/$1" match=$2
    shift 2
    file=$(find "$dir" -maxdepth 2 -iname "$match" 2>/dev/null | sort | head -n 1)
    if [ -z "$file" ]; then
      echo "No $match in $dir: download it in LM Studio" >&2
      exit 1
    fi
    exec ${lib.getExe' pkgs.llama-cpp-vulkan "llama-server"} -m "$file" "$@"
  '';

  modelsDir = "${config.home.homeDirectory}/.lmstudio/models";

  #--- Whole model on the GPU: shared memory leaves no reason to keep experts on the CPU
  #--- Both take images through their mmproj file (`--mmproj`)
  models = {
    #--- Main model, for opencode and hard problems: MoE, 6B active (84 GiB at
    #--- UD-Q3_K_XL; Q4 would leave too little RAM free)
    qwen3_8-flash-next = {
      name = "Qwen3.8 Flash Next";
      dir = "unsloth/Qwen3.8-Flash-Next-GGUF";
      match = "Qwen3.8-Flash-Next-UD-Q3_K_XL-00001-of-*.gguf";
      context = 131072;
      slots = 1; # No room for a second slot's cache under the 96 GB budget
      # q8_0 V cache: ~17% faster prompts at 32K, perplexity within error
      flags = [
        "-ctv q8_0"
        "--mmproj '${modelsDir}/unsloth/Qwen3.8-Flash-Next-GGUF/mmproj-F16.gguf'"
      ];
      #--- Qwen's thinking-mode sampling
      params = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 20;
        min_p = 0;
        presence_penalty = 0.0;
      };
      fast = null;
    };
    #--- opencode's default: the coordinator session plus 3 parallel subagents, one
    #--- slot each. MoE, 3B active (21 GiB at UD-Q4_K_XL, ~25% faster generation
    #--- than Q8 here); 10 of 40 layers keep a cache, so 4 x 128K is ~11 GB in f16
    qwen3_6-35b-a3b = {
      name = "Qwen3.6 35B A3B";
      dir = "unsloth/Qwen3.6-35B-A3B-GGUF";
      match = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
      context = 131072;
      slots = 4;
      flags = ["--mmproj '${modelsDir}/unsloth/Qwen3.6-35B-A3B-GGUF/mmproj-F16.gguf'"];
      #--- Coordinator: Qwen's thinking-mode coding sampling
      params = {
        temperature = 0.6;
        top_p = 0.95;
        top_k = 20;
        min_p = 0;
        presence_penalty = 0.0;
      };
      #--- Workers (the -instruct alias): thinking off, Qwen's non-thinking sampling
      fast = {
        chat_template_kwargs.enable_thinking = false;
        temperature = 0.7;
        top_p = 0.8;
        top_k = 20;
        min_p = 0;
        presence_penalty = 1.5;
      };
    };
  };

  settings = {
    models =
      lib.mapAttrs (id: m: {
        ttl = 600; # Unloads after 10 idle minutes
        cmd = lib.concatStringsSep " " ([
            launch
            "'${m.dir}'"
            "'${m.match}'"
            "--port \${PORT}"
            # Several slots share one cache pool of `slots` x `context`
            (
              if m.slots == 1
              then "-c ${toString m.context} -np 1"
              else "-np ${toString m.slots} -kvu --kv-unified-per-slot ${toString m.context}"
            )
            "-fa on -ngl 99 --load-mode none -ub 2048 --no-webui"
            "-ctk f16 -ctv f16"
          ]
          ++ m.flags);
        # The -instruct key also registers as an alias of the same loaded model
        filters.setParamsByID =
          {${id} = m.params;}
          // lib.optionalAttrs (m.fast != null) {"${id}-instruct" = m.fast;};
      })
      models;
    #--- One model loaded at a time
    groups.gpu = {
      swap = true;
      exclusive = true;
      members = lib.attrNames models;
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Service
  #--------------------------------------------------------------------#
  systemd.user.services.llama-swap = {
    Unit.Description = "llama-swap local LLM server";
    Install.WantedBy = ["default.target"];
    Service = {
      ExecStart = "${lib.getExe pkgs.llama-swap} -listen 127.0.0.1:${toString port} -config ${(pkgs.formats.yaml {}).generate "llama-swap.yaml" settings}";
      Restart = "on-failure";
    };
  };

  #--------------------------------------------------------------------#
  #-- OpenCode Provider
  #--------------------------------------------------------------------#
  #--- opencode in a window; it reads the same settings as the terminal one.
  #--- ask-claude: the coordinators' last resort, a one-off read-only Claude Code
  #--- run in the current folder that prints its answer
  home.packages = [
    pkgs.opencode-desktop
    (pkgs.writeShellScriptBin "ask-claude" ''
      if [ $# -eq 0 ]; then
        echo 'usage: ask-claude "<self-contained question>"' >&2
        exit 2
      fi
      exec claude -p --permission-mode plan --no-session-persistence "$*"
    '')
  ];

  programs.opencode.settings = {
    model = "llama-swap/qwen3_6-35b-a3b";
    # Titles and summaries on the workers' alias, so the model stays loaded
    small_model = "llama-swap/qwen3_6-35b-a3b-instruct";
    #--- Two coordinators (Tab switches): `system` for this computer, the default,
    #--- and `gamedev` for the Godot game, which its project's opencode.json picks.
    #--- The subagents they start run on the workers' alias
    default_agent = "system";
    agent =
      lib.genAttrs ["general" "explore"] (_: {
        model = "llama-swap/qwen3_6-35b-a3b-instruct";
      })
      // {
        system = {
          description = "Answers questions about this computer and fixes its errors";
          mode = "primary";
          model = "llama-swap/qwen3_6-35b-a3b";
          prompt = builtins.readFile ./agents/system.md;
        };
        gamedev = {
          description = "Coordinates work on the Godot game Clocked Out";
          mode = "primary";
          model = "llama-swap/qwen3_6-35b-a3b";
          prompt = builtins.readFile ./agents/gamedev.md;
        };
      };
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options.baseURL = "http://127.0.0.1:${toString port}/v1";
      models = lib.concatMapAttrs (id: m: let
        model = name: output: {
          inherit name;
          modalities = {
            input = ["text" "image"];
            output = ["text"];
          };
          limit = {
            inherit (m) context;
            inherit output;
          };
        };
      in
        {${id} = model m.name 32768;}
        // lib.optionalAttrs (m.fast != null) {
          "${id}-instruct" = model "${m.name} (fast)" 8192;
        })
      models;
    };
  };
}
