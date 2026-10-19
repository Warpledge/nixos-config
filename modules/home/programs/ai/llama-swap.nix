#=====================================================================#
# LLAMA-SWAP - LOCAL LLM SERVER (LLAMA.CPP, VULKAN)
#=====================================================================#
{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  port = 8090; # 8080 is taken by Steam's webhelper
  llamaServer = lib.getExe' pkgs.llama-cpp-vulkan "llama-server";
  models = "${config.home.homeDirectory}/.lmstudio/models";

  #--- MoE, 3B active. Only 10 of its 40 layers keep a KV cache (the rest are
  #--- Gated DeltaNet), so 128K context costs ~1.4GB at q8_0
  qwen = [
    llamaServer
    "--port \${PORT}"
    "-m ${models}/unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-Q3_K_XL.gguf"
    "-ngl 99"
    # Experts of the first N layers run from RAM (~0.4GB each); attention and
    # KV stay on the GPU. Lower it for speed while VRAM stays under ~13GB.
    "--n-cpu-moe 20"
    "-c 131072" # opencode's own prompt and tools take ~27K
    "-np 1" # One slot, so it gets the whole context
    "-ub 2048" # Larger prefill batches: fewer expert copies over PCIe
    "-fa on"
    "-ctk q8_0"
    "-ctv q8_0"
    "--top-k 20"
    "--min-p 0"
    "--no-webui"
  ];

  #--- Loads on the first request, unloads after `ttl` idle seconds to free VRAM
  settings = {
    #--- Qwen's thinking-mode sampling for coding
    models."qwen3.6-35b-a3b" = {
      ttl = 600;
      cmd = lib.concatStringsSep " " (qwen ++ ["--temp 0.6" "--top-p 0.95"]);
    };
    #--- Same weights, no thinking: faster replies for single-step edits
    models."qwen3.6-35b-a3b-instruct" = {
      ttl = 600;
      cmd = lib.concatStringsSep " " (qwen
        ++ [
          "--reasoning off"
          # Qwen's non-thinking sampling
          "--temp 0.7"
          "--top-p 0.8"
          "--presence-penalty 1.5"
        ]);
    };
    #--- Zed edit predictions: a next-edit model, not instruct
    models."sweep-next-edit-1.5b" = {
      ttl = 600;
      cmd = lib.concatStringsSep " " [
        llamaServer
        "--port \${PORT}"
        "-m ${models}/sweepai/sweep-next-edit-1.5B/sweep-next-edit-1.5b.q8_0.v2.gguf"
        # CPU only: keeps the VRAM for the 35B; -ngl 0 alone still allocates GPU buffers
        "--device none"
        "-c 32768" # Zed's prediction prompts reach ~16K
        "--cache-reuse 256" # Reuses the cached prompt between keystrokes
        "-np 1"
        "-fa on"
        "--no-webui"
      ];
    };
    #--- One Qwen variant at a time; switching reloads it (from page cache)
    groups.chat = {
      swap = true;
      exclusive = false;
      members = ["qwen3.6-35b-a3b" "qwen3.6-35b-a3b-instruct"];
    };
    #--- Stays loaded beside either variant
    groups.predict = {
      swap = false;
      exclusive = false;
      persistent = true;
      members = ["sweep-next-edit-1.5b"];
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
  programs.opencode.settings = lib.mkIf user.opencode.enable {
    model = "llama-swap/qwen3.6-35b-a3b";
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options.baseURL = "http://127.0.0.1:${toString port}/v1";
      models."qwen3.6-35b-a3b" = {
        name = "Qwen3.6 35B A3B";
        limit = {
          context = 131072;
          output = 16384; # Thinking tokens count against it
        };
      };
      models."qwen3.6-35b-a3b-instruct" = {
        name = "Qwen3.6 35B A3B (no thinking)";
        limit = {
          context = 131072;
          output = 8192;
        };
      };
    };
  };
}
