# Local AI models on the Flow Z13

Every model tested or tuned on this machine, with the settings it ended on and what
it measured, so the next change starts from these numbers instead of from scratch.
`home/local-ai.nix` holds the live settings. Memory budget for models: 80 GB (Ky,
2026-10-27), leaving the rest of the 128 GB for everything else.

## How models are tested

The scripts in `local-ai-bench/` run against a llama-server started by hand on a
spare port (8095), with llama-swap's model unloaded so the two don't share memory:

- `bench.py URL MODEL LABEL [IMAGE]`: generation and prompt speed, 4 requests at
  once, a coordinator tool-discipline test (delegate an edit, split two tasks,
  refuse a shared file, resist a "just use sed" request), three coding tasks
  checked by hidden tests (`retry_after`, `safe_join`, `lazy_chunks`), and a vision
  description of the game's `tests/baseline/pose_05_aisle.png`.
- `followup.py URL MODEL LABEL`: the same coordinator prompts over several turns,
  answering `read` and read-only shell calls for real. The single-turn test scores
  a model low when it reads a file before delegating; this one shows where it goes.
- `speed.py URL` and `par2.py URL N`: generation speed alone and with N thinking
  requests at once.
- `vision.py URL IMAGE`: the frame description with thinking off, then on.

`BENCH_EXTRA='{"temperature":1.0,"top_p":0.95}'` passes the model's own sampling.
GPU memory is `mem_info_gtt_used` plus `mem_info_vram_used` under
`/sys/class/drm/card1/device/`.

## Nemotron 3.5 Super VL 120B-A12B (current, since 2026-10-27)

- **File:** `unsloth/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-GGUF`, UD-Q3_K_XL
  (65.8 GB) plus `mmproj-BF16.gguf` (1.7 GB). Q4_K_XL is 86.9 GB, over budget.
- **Needs llama.cpp 0.7.0 or newer** (support merged 2026-10-15). nixpkgs had 0.6.0,
  so `local-ai.nix` builds 0.7.0 with its tests off: `test-download-model` needs the
  network, which the Nix sandbox blocks.
- **Settings:** `-np 3 -kvu --kv-unified-per-slot 65536 -fa on -ngl 99 --load-mode
  none -ub 2048 -ctk f16 -ctv f16 --spec-type draft-mtp --top-k 0 --min-p 0`.
  Temperature 1.0 and top_p 0.95, NVIDIA's values. The coordinator uses
  `enable_thinking`; workers add `medium_effort` through the `-instruct` alias.
  opencode's context is 65536 with a 16384 output limit, so it compacts near 48K.
- **Memory:** 72 GB of GPU memory with 3 slots and MTP; 66 GB with 4 slots and no
  MTP; 74 GB with 4 slots and MTP. Loads in about 25 seconds.
- **Speed, thinking on (tok/s):**

  | Requests at once | No MTP | MTP |
  |---|---|---|
  | 1 | 18.6 | 28.4 |
  | 2 | 26.0 | 29.0 |
  | 3 | 30.2 | 24.6 |
  | 4 | 30.9 | 19.6 |

  MTP accepted 84% of drafts on code and about 52% on plain prose (21 tok/s alone).
  It wins with one or two requests and loses beyond that, so the config runs 3
  slots: one coordinator and two workers. Prompt reading: 306 tok/s at 19K tokens.
- **`medium_effort`:** the same coding prompt used 726 tokens against 2,283 with
  full reasoning.
- **Results:**
  - Coding: 3/3, but slow, at 3,600 to 7,200 tokens and 3.5 to 6.5 minutes a task.
  - Vision: described the aisle frame correctly (blue racking, boxes, fluorescent
    lights, no text, nothing broken). It didn't mention the crosshair.
  - Coordinator: no direct edits or shell writes in any run. It refused the shared
    file both times and handed the "just use sed" change to a subagent. Over
    several turns it read the target file first, noticed when a bind already
    existed, split independent work across two subagents, and caught a fake
    worker that claimed success without making the change, then re-delegated.
    It tried `sudo journalctl` once when logs were empty.
- **Published comparison (NVIDIA's model card, vendor numbers):** below Qwen3.8
  Flash Next on most coding and agent rows (Terminal-Bench 2.1: 66.7 against 85.8;
  SWE-bench Pro: 51.8 against 60.4); above Qwen3.5-122B-A10B on coding and agent
  rows, below it on vision.

## Qwen3.6 35B A3B (dropped 2026-10-27)

- **File:** `unsloth/Qwen3.6-35B-A3B-GGUF`, UD-Q4_K_XL (21 GiB) plus
  `mmproj-F16.gguf`. About 25% faster generation than Q8 on this machine.
- **Settings used:** 4 slots of 128K with `-kvu`, f16 cache (only 10 of its 40
  layers keep one, so 4 x 128K is about 11 GB). Thinking on for the coordinator
  (temperature 0.6, top_p 0.95, top_k 20), off for workers (0.7, 0.8, presence
  penalty 1.5). About 37 GB of GPU memory loaded.
- **Speed:** about 46 tok/s alone; prompt reading 600 to 1,600 tok/s, falling to
  310 tok/s for a 106K prompt with 3 other requests running (6 minutes for one turn).
- **Why it was dropped:** as a coordinator it never delegated (94 steps without a
  subagent call), edited files through `sed` and `mv` after edits were denied,
  changed git remotes, ran garbage collection unasked, wrote to Warpledge's shared
  files, and ran `git checkout HEAD -- .` over uncommitted game work. Ky also found
  its code poor. An independent Strix Halo coding test scored it 6/10.

## Qwen3.8 Flash Next (replaced 2026-10-27, files still on disk)

- **File:** `unsloth/Qwen3.8-Flash-Next-GGUF`, UD-Q3_K_XL (84 GiB) plus
  `mmproj-F16.gguf`. Q4 is 111 GB.
- **Settings:** one slot of 128K, f16 K cache and q8_0 V cache (about 17% faster
  prompts at 32K with perplexity within error), Qwen's thinking sampling
  (temperature 1.0, top_p 0.95, top_k 20).
- **Memory:** 68 GB GPU memory plus 36 GB in llama-server's own process with one
  128K slot. That left too little for everything else, and it ran out of memory.
- Good results by Ky's account, but slow. No speed numbers were recorded.

## Earlier models (2026-10-25, from commit messages)

- **DeepSeek V4 Flash:** UD-IQ3_XXS, 97 GiB, 13B active. Its DSpark drafter (10 GiB)
  nearly doubled generation but left about 1 GiB of RAM free. Thinking capped at
  4096 tokens.
- **gpt-oss-120b:** MXFP4, 59 GiB, 5B active. Read input about 3 times faster than
  DeepSeek. Text only.
- **Ornith 1.5 35B A3B:** replaced by the two above the same day.

## gpt-oss-120b with a Qwen3.5-9B vision helper (tested 2026-10-27, not in use)

The text-only main model for the coordinator and workers, plus a small vision model
loaded beside it only when an image needs looking at.

- **Files:** `ggml-org/gpt-oss-120b-GGUF`, MXFP4 (63.3 GB, 5.1B active, text only).
  `unsloth/Qwen3.5-9B-GGUF`, UD-Q4_K_XL (6.0 GB) plus `mmproj-F16.gguf` (0.9 GB).
  LM Studio wouldn't fetch the mmproj; it came straight from Hugging Face.
- **gpt-oss settings tested:** `-np 3 -kvu --kv-unified-per-slot 65536 -fa on -ngl 99
  --load-mode none -ub 2048`, f16 cache, temperature 1.0, top_p 1.0 (OpenAI's),
  `chat_template_kwargs.reasoning_effort = "high"`. Its template ignores
  `enable_thinking`; effort is low, medium or high.
- **Vision helper settings tested:** `-np 1 -c 32768 -fa on -ngl 99`, temperature 0.7,
  top_p 0.8, top_k 20 (Qwen's non-thinking values).
- **Memory:** gpt-oss alone 69 GB; with the helper loaded 77 GB.
- **gpt-oss speed:** 45 tok/s alone, 53 tok/s total with 4 requests, prompt reading
  849 tok/s at 19K tokens. About 2.5 times Nemotron on all three.
- **Results:**
  - Coding: 2/3 in 1 to 2 minutes a task. It missed that `lazy_chunks` must raise
    on the call rather than on the first `next()`.
  - Coordinator: refused the shared file, split work across three subagents over
    several turns, and noticed the existing bind. In one run it called the `edit`
    tool directly, which opencode's deny would have blocked; Nemotron never tried.
  - Vision (helper): with thinking off, 15 s and mostly right, but it made up
    "flickering" lights and guessed the engine (Unity). With thinking on, 47 s and
    accurate, including the flat untextured shading.
