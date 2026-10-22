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
  #--- `args` start the server; `think`, `fast` and the optional `chat` are request
  #--- parameters llama-swap forces on <name> and its <name>-instruct and <name>-chat
  #--- aliases, so all three share one loaded model
  #--- --load-mode none: experts in RAM read into memory, not paged in from the file
  code = {
    #--- MoE, 3B active; 10 of its 40 layers keep a KV cache, so 128K is ~1.4GB
    "qwen3.6-35b-a3b" = {
      name = "Qwen3.6 35B A3B (Q3)";
      dir = "unsloth/Qwen3.6-35B-A3B-GGUF";
      match = "*UD-Q3_K_XL*.gguf";
      context = 131072;
      # Experts of 18 layers from RAM: ~15GB VRAM (20 measured 80-85%, 37-39 tok/s)
      args = ["-ngl 99" "--load-mode none" "--n-cpu-moe 18" "-ub 2048" "--top-k 20" "--min-p 0"];
      # Qwen's general-chat sampling, for Open WebUI
      chat = {
        temperature = 1.0;
        top_p = 0.95;
        presence_penalty = 1.5;
      };
      # Qwen's thinking-mode coding sampling, and its non-thinking sampling;
      # presence_penalty (0-2 per Qwen) curbs the repetition loops a quant falls into
      think = {
        temperature = 0.6;
        top_p = 0.95;
        presence_penalty = 1.0;
      };
      fast = {
        chat_template_kwargs.enable_thinking = false;
        temperature = 0.7;
        top_p = 0.8;
        presence_penalty = 1.5;
      };
    };
    "qwen3.6-35b-a3b-q4" = {
      name = "Qwen3.6 35B A3B (Q4)";
      dir = "unsloth/Qwen3.6-35B-A3B-GGUF";
      match = "*UD-Q4_K_XL*.gguf";
      context = 131072;
      # Experts of 24 layers from RAM: measured ~89% VRAM, 38 tok/s
      args = ["-ngl 99" "--load-mode none" "--n-cpu-moe 24" "-ub 2048" "--top-k 20" "--min-p 0"];
      chat = {
        temperature = 1.0;
        top_p = 0.95;
        presence_penalty = 1.5;
      };
      think = {
        temperature = 0.6;
        top_p = 0.95;
        presence_penalty = 1.0;
      };
      fast = {
        chat_template_kwargs.enable_thinking = false;
        temperature = 0.7;
        top_p = 0.8;
        presence_penalty = 1.5;
      };
    };
    #--- Qwen3.6's MoE architecture, trained further for coding agents. Its MTP head
    #--- stays off: drafts route more tokens through the experts in RAM
    "ornith-1.5-35b-a3b" = {
      name = "Ornith 1.5 35B A3B";
      dir = "ornith-ai/Ornith-1.5-35B-A3B-GGUF";
      match = "*Q4_K_M*.gguf";
      context = 131072;
      # ~0.5GB per layer's experts: 23 in RAM, ~15.3GB (26 measured 13.9GB, 35 tok/s)
      args = ["-ngl 99" "--load-mode none" "--n-cpu-moe 23" "-ub 2048" "--top-k 20" "--min-p 0"];
      # The model card's coding sampling
      think = {
        temperature = 0.6;
        top_p = 0.95;
      };
      fast = {
        chat_template_kwargs.enable_thinking = false;
        temperature = 0.7;
        top_p = 0.8;
        presence_penalty = 1.5;
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- Chat Models
  #--------------------------------------------------------------------#
  #--- Same fields as the coding models; 32K is plenty for a conversation
  chat = {
    #--- MoE, 3.6B active, MXFP4 weights (~13GB); reasoning can't be turned off
    "gpt-oss-20b" = {
      name = "gpt-oss 20B";
      dir = "ggml-org/gpt-oss-20b-GGUF";
      match = "*.gguf";
      context = 32768;
      args = ["--fit-target 2048"];
      # OpenAI's sampling; medium effort, and low for the fast variant
      think = {
        temperature = 1.0;
        top_p = 1.0;
        chat_template_kwargs.reasoning_effort = "medium";
      };
      fast = {
        temperature = 1.0;
        top_p = 1.0;
        chat_template_kwargs.reasoning_effort = "low";
      };
    };
    #--- MoE, 3.8B active; the QAT file (~14GB) is Google's 4-bit training
    "gemma-4-26b-a4b" = {
      name = "Gemma 4 26B A4B";
      dir = "unsloth/gemma-4-26B-A4B-it-qat-GGUF";
      match = "*UD-Q4_K_XL*.gguf";
      context = 32768;
      args = ["--fit-target 2048" "--load-mode none"];
      think = {
        # Google's sampling
        temperature = 1.0;
        top_p = 0.95;
        top_k = 64;
      };
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
