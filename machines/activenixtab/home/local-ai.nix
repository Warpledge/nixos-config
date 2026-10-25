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
  models = {
    #--- Most accurate, for chat and hard problems: MoE, 13B active (97 GiB at
    #--- UD-IQ3_XXS). The DSpark drafter (10 GiB) nearly doubles generation but
    #--- leaves ~1 GiB RAM free while loaded. Thinking is capped at 4096 tokens.
    deepseek-v4-flash = {
      name = "DeepSeek V4 Flash";
      dir = "unsloth/DeepSeek-V4-Flash-0731-GGUF";
      match = "DeepSeek-V4-Flash-0731-*-00001-of-*.gguf";
      context = 65536;
      flags = [
        "--reasoning-budget 4096"
        "-md '${modelsDir}/unsloth/DeepSeek-V4-Flash-0731-GGUF/dspark-DeepSeek-V4-Flash-0731-Q8_0.gguf'"
        "--spec-type draft-dspark --spec-draft-n-max 3 -ngld 99"
      ];
      #--- Unsloth's sampling for V4 Flash
      params = {
        temperature = 1.0;
        top_p = 1.0;
        min_p = 0.01;
      };
    };
    #--- Fast, for opencode: MoE, 5B active (59 GiB, MXFP4 as released).
    #--- Reads input ~3x faster than DeepSeek
    gpt-oss-120b = {
      name = "gpt-oss 120B";
      dir = "ggml-org/gpt-oss-120b-GGUF";
      match = "gpt-oss-120b-*.gguf";
      context = 131072;
      flags = ["--reasoning-effort medium"];
      #--- OpenAI's sampling for gpt-oss
      params = {
        temperature = 1.0;
        top_p = 1.0;
        top_k = 0;
        min_p = 0;
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
            "-c ${toString m.context}"
            "-np 1 -fa on -ngl 99 --load-mode none -ub 2048 --no-webui"
            "-ctk f16 -ctv f16"
          ]
          ++ m.flags);
        filters.setParamsByID.${id} = m.params;
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
  #--- opencode in a window; it reads the same settings as the terminal one
  home.packages = [pkgs.opencode-desktop];

  programs.opencode.settings = {
    model = "llama-swap/gpt-oss-120b";
    # Titles and summaries too: another model would swap the big one out
    small_model = "llama-swap/gpt-oss-120b";
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options.baseURL = "http://127.0.0.1:${toString port}/v1";
      models =
        lib.mapAttrs (_: m: {
          inherit (m) name;
          limit = {
            inherit (m) context;
            output = 32768;
          };
        })
        models;
    };
  };
}
