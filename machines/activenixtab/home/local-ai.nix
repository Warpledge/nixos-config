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

  #--- Finds a download in its LM Studio folder, whatever the file's exact name
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

  #--- Whole model on the GPU: shared memory leaves no reason to keep experts on the CPU
  models = {
    #--- Default for opencode: MoE, 3B active, no thinking mode (~49 GB)
    qwen3-coder-next = {
      name = "Qwen3 Coder Next 80B A3B";
      dir = "unsloth/Qwen3-Coder-Next-GGUF";
      match = "*Q4_K_M*.gguf";
      context = 262144;
      cache = "f16";
      params = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 40;
      };
      code = true;
    };
    #--- Faster, thinks first (~21 GB)
    qwen3-6-35b-a3b = {
      name = "Qwen3.6 35B A3B";
      dir = "unsloth/Qwen3.6-35B-A3B-GGUF";
      match = "*UD-Q4_K_XL*.gguf";
      context = 131072;
      cache = "f16";
      params = {
        temperature = 0.6;
        top_p = 0.95;
        top_k = 20;
        min_p = 0;
      };
      code = true;
    };
    #--- Chat (~63 GB)
    gpt-oss-120b = {
      name = "gpt-oss 120B";
      dir = "ggml-org/gpt-oss-120b-GGUF";
      match = "gpt-oss-120b-MXFP4.gguf";
      context = 131072;
      cache = "q8_0";
      params = {
        temperature = 1.0;
        top_p = 1.0;
        chat_template_kwargs.reasoning_effort = "medium";
      };
      code = false;
    };
  };

  settings = {
    models =
      lib.mapAttrs (id: m: {
        ttl = 600; # Unloads after 10 idle minutes
        cmd = lib.concatStringsSep " " [
          launch
          "'${m.dir}'"
          "'${m.match}'"
          "--port \${PORT}"
          "-c ${toString m.context}"
          "-np 1 -fa on -ngl 99 --load-mode none -ub 2048 --no-webui"
          "-ctk ${m.cache} -ctv ${m.cache}"
        ];
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
  codeModels = lib.filterAttrs (_: m: m.code) models;
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
  programs.opencode.settings = {
    model = "llama-swap/qwen3-coder-next";
    small_model = "llama-swap/qwen3-coder-next";
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
        codeModels;
    };
  };
}
