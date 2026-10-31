#=====================================================================#
# LOCAL AI MODELS
#=====================================================================#
#- The models a user's localAi settings can pick, served by llama-swap
#- (home/programs/ai/llama-swap.nix). Each file is found by `match` inside
#- `dir` under ~/.lmstudio/models, where LM Studio saves a download of the
#- `dir` repo. `tuned.<profile>` holds offload measured on that GPU
#- (gpu-profiles.nix); lib/local-ai.nix turns it into flags per machine,
#- where a machine's localModels block can add models and change tuning.
#- Omni Settings' labels and download notes are in its descriptions.json.
{
  #--------------------------------------------------------------------#
  #-- Coding Models
  #--------------------------------------------------------------------#
  #--- `args` start the server; `think`, `fast` and the optional `chat` are request
  #--- parameters llama-swap forces on <name> and its <name>-instruct and <name>-chat
  #--- aliases, so all three share one loaded model
  #--- `tuned` fields: gpuLayers (-ngl), loadMode, cpuMoe (--n-cpu-moe), batch (-ub),
  #--- cacheRam, fitTarget, and context or cache in place of the model's own
  #--- loadMode "none": experts in RAM read into memory, not paged in from the file
  #--- `cache`, optional: the KV cache type in place of q8_0
  code = {
    #--- MoE, 3B active; 10 of its 40 layers keep a KV cache, so 128K is ~1.4GB
    "qwen3.6-35b-a3b-q4" = {
      name = "Qwen3.6 35B A3B (Q4)";
      dir = "unsloth/Qwen3.6-35B-A3B-GGUF";
      match = "*UD-Q4_K_XL*.gguf";
      context = 131072;
      # f16 cache: q8_0's error weighs more with only 10 KV layers at long context
      cache = "f16";
      # Experts of 22 layers from RAM, to make room for the f16 cache (18 with q8_0
      # reached 98% VRAM). Prompt cache in RAM halved from 8GB: RAM reached 88%
      tuned.rx-9070-xt = {
        gpuLayers = 99;
        loadMode = "none";
        cpuMoe = 22;
        batch = 2048;
        cacheRam = 4096;
      };
      # The reasoning budget cuts a thinking loop off; the message is Qwen's own
      args = [
        "--top-k 20"
        "--min-p 0"
        "--reasoning-budget 8192"
        "--reasoning-budget-message 'Considering the limited time by the user, I have to give the solution based on the thinking directly now.'"
      ];
      # Qwen's general-chat sampling, for Open WebUI
      chat = {
        temperature = 1.0;
        top_p = 0.95;
        presence_penalty = 1.5;
      };
      # Qwen's thinking-mode coding sampling, and its non-thinking sampling;
      # preserve_thinking keeps earlier turns' reasoning in an agent session
      think = {
        temperature = 0.6;
        top_p = 0.95;
        presence_penalty = 0.0;
        chat_template_kwargs.preserve_thinking = true;
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
      # ~0.5GB per layer's experts: 20 in RAM, ~15GB (23 measured 85% VRAM, 36 tok/s).
      # Same prompt cache as Qwen3.6
      tuned.rx-9070-xt = {
        gpuLayers = 99;
        loadMode = "none";
        cpuMoe = 20;
        batch = 2048;
        cacheRam = 4096;
      };
      # Same reasoning budget and message as Qwen3.6
      args = [
        "--top-k 20"
        "--min-p 0"
        "--reasoning-budget 8192"
        "--reasoning-budget-message 'Considering the limited time by the user, I have to give the solution based on the thinking directly now.'"
      ];
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
      tuned.rx-9070-xt.fitTarget = 2048;
      args = [];
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
      tuned.rx-9070-xt = {
        fitTarget = 2048;
        loadMode = "none";
      };
      args = [];
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
