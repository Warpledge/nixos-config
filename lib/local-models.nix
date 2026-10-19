#=====================================================================#
# LOCAL AI MODELS
#=====================================================================#
#- The models a user's localAi settings can pick, served by llama-swap
#- (home/programs/ai/llama-swap.nix). Each file is found by `match` inside
#- `dir` under ~/.lmstudio/models, where LM Studio saves a download of the
#- `dir` repo. Offload and context are tuned for eclipse's 16GB RX 9070 XT.
#- lib/settings.nix takes the dropdown choices from the attribute names;
#- NixOS Settings' labels and download notes are in its descriptions.json.
{
  #--------------------------------------------------------------------#
  #-- Coding Models
  #--------------------------------------------------------------------#
  #--- `args` are shared; `think`/`temp` and `fast`/`fastTemp` are the two variants'
  #--- flags and temperature (fast is served as <name>-instruct; null: none). Zed
  #--- sends its own temperature, so it reads `temp` too.
  code = {
    #--- MoE, 3B active; 10 of its 40 layers keep a KV cache, so 128K is ~1.4GB
    "qwen3.6-35b-a3b" = {
      name = "Qwen3.6 35B A3B";
      dir = "unsloth/Qwen3.6-35B-A3B-GGUF";
      match = "*UD-Q3_K_XL*.gguf";
      context = 131072;
      # Experts of the first 20 layers from RAM: ~13.8GB VRAM, ~37 tok/s
      args = ["-ngl 99" "--n-cpu-moe 20" "-ub 2048" "--top-k 20" "--min-p 0"];
      temp = 0.6; # Qwen's thinking-mode coding sampling
      think = ["--top-p 0.95"];
      fastTemp = 0.7; # and its non-thinking sampling
      fast = ["--reasoning off" "--top-p 0.8" "--presence-penalty 1.5"];
    };
    "qwen3.6-35b-a3b-q4" = {
      name = "Qwen3.6 35B A3B (Q4)";
      dir = "unsloth/Qwen3.6-35B-A3B-GGUF";
      match = "*UD-Q4_K_XL*.gguf";
      context = 131072;
      # ~0.5GB per layer's experts, so 24 from RAM for the same ~13.8GB
      args = ["-ngl 99" "--n-cpu-moe 24" "-ub 2048" "--top-k 20" "--min-p 0"];
      temp = 0.6;
      think = ["--top-p 0.95"];
      fastTemp = 0.7;
      fast = ["--reasoning off" "--top-p 0.8" "--presence-penalty 1.5"];
    };
    #--- Dense 27B; --fit keeps layers on the GPU while 2GB of VRAM stays free
    "qwen3.8-27b" = {
      name = "Qwen3.8 27B";
      dir = "unsloth/Qwen3.8-27B-GGUF";
      match = "*UD-Q3_K_XL*.gguf";
      context = 65536; # Every layer is on the GPU path, so less room for cache
      args = ["--fit-target 2048" "--top-k 20" "--min-p 0"];
      temp = 0.6;
      think = ["--top-p 0.95"];
      fastTemp = 0.7;
      fast = ["--reasoning off" "--top-p 0.8" "--presence-penalty 1.5"];
    };
    #--- MoE, 3.6B active, MXFP4 weights (~13GB); reasoning can't be turned off
    "gpt-oss-20b" = {
      name = "gpt-oss 20B";
      dir = "ggml-org/gpt-oss-20b-GGUF";
      match = "*.gguf";
      context = 131072;
      args = ["--fit-target 2048" "-ub 2048" "--top-p 1.0"];
      temp = 1.0;
      fastTemp = 1.0;
      think = ["--chat-template-kwargs '{\"reasoning_effort\":\"high\"}'"];
      fast = ["--chat-template-kwargs '{\"reasoning_effort\":\"low\"}'"];
    };
    #--- MoE, 2B active; always reasons first
    "lfm2.5-24b-a2b" = {
      name = "LFM2.5 24B A2B";
      dir = "unsloth/LFM2.5-24B-A2B-GGUF";
      match = "*UD-Q3_K_XL*.gguf";
      context = 131072;
      # Liquid AI's suggested sampling
      args = ["--fit-target 2048" "--min-p 0.15" "--repeat-penalty 1.05"];
      temp = 0.1;
      think = [];
      fast = null;
    };
  };

  #--------------------------------------------------------------------#
  #-- Inline Suggestion Models (Zed)
  #--------------------------------------------------------------------#
  #--- CPU only, so the coding model keeps the VRAM; `format` is Zed's prompt_format
  edit = {
    "sweep-next-edit-1.5b" = {
      name = "Sweep Next-Edit 1.5B";
      dir = "sweepai/sweep-next-edit-1.5B";
      match = "*.gguf";
      format = "sweep";
      context = 32768; # Zed's prediction prompts reach ~16K
    };
    #--- Fill-in-the-middle only: completes at the cursor, no edits elsewhere
    "qwen2.5-coder-1.5b" = {
      name = "Qwen2.5 Coder 1.5B";
      dir = "ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF";
      match = "*.gguf";
      format = "qwen";
      context = 8192;
    };
  };
}
