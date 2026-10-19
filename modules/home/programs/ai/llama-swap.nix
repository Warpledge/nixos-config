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

  #--- Loads on the first request, unloads after `ttl` idle seconds to free VRAM
  settings = {
    models."lfm2.5-24b-a2b" = {
      ttl = 600;
      cmd = lib.concatStringsSep " " [
        llamaServer
        "--port \${PORT}"
        "-m ${models}/unsloth/LFM2.5-24B-A2B-GGUF/LFM2.5-24B-A2B-UD-Q3_K_XL.gguf"
        "-ngl 99"
        "-c 65536" # opencode's own prompt and tools take ~27K
        "-np 1" # One slot, so it gets the whole context
        "-fa on"
        "-ctk q8_0"
        "-ctv q8_0"
        # Liquid AI's suggested sampling
        "--temp 0.1"
        "--min-p 0.15"
        "--repeat-penalty 1.05"
        "--no-webui"
      ];
    };
    #--- Zed edit predictions: a next-edit model, not instruct
    models."sweep-next-edit-1.5b" = {
      ttl = 600;
      cmd = lib.concatStringsSep " " [
        llamaServer
        "--port \${PORT}"
        "-m ${models}/sweepai/sweep-next-edit-1.5B/sweep-next-edit-1.5b.q8_0.v2.gguf"
        "-ngl 0" # On the CPU: the desktop's VRAM is full with the 24B loaded
        "-c 32768" # Zed's prediction prompts reach ~16K
        "--cache-reuse 256" # Reuses the cached prompt between keystrokes
        "-np 1"
        "-fa on"
        "--no-webui"
      ];
    };
    #--- Both stay loaded, so neither unloads the other
    groups.editor = {
      swap = false;
      exclusive = true;
      members = ["lfm2.5-24b-a2b" "sweep-next-edit-1.5b"];
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
    model = "llama-swap/lfm2.5-24b-a2b";
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options.baseURL = "http://127.0.0.1:${toString port}/v1";
      models."lfm2.5-24b-a2b" = {
        name = "LFM2.5 24B A2B";
        limit = {
          context = 65536;
          output = 8192;
        };
      };
    };
  };
}
