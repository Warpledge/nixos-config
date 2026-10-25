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

  #--- Whole model on the GPU: shared memory leaves no reason to keep experts on the CPU
  models = {
    #--- Default, for coding and chat: MoE, 10B active (~79 GB in three parts).
    #--- 12 of its 48 layers keep a KV cache, so 256K is ~6 GB at f16
    ornith-1-5-122b = {
      name = "Ornith 1.5 122B";
      dir = "unsloth/Ornith-1.5-122B-GGUF";
      match = "*UD-Q4_K_XL*.gguf";
      context = 262144;
    };
    #--- Same family, 3B active, for quick edits (~23 GB)
    ornith-1-5-35b = {
      name = "Ornith 1.5 35B A3B";
      dir = "ornith-ai/Ornith-1.5-35B-A3B-GGUF";
      match = "*Q4_K_M*.gguf";
      context = 131072;
    };
  };
  #--- Ornith's sampling for coding
  params = {
    temperature = 0.6;
    top_p = 0.95;
    top_k = 20;
    min_p = 0;
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
          "-ctk f16 -ctv f16"
        ];
        filters.setParamsByID.${id} = params;
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
    model = "llama-swap/ornith-1-5-122b";
    # Titles and summaries too: another model would swap the big one out
    small_model = "llama-swap/ornith-1-5-122b";
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
