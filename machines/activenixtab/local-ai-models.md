# Local AI models on the Flow Z13

What each model tested on this machine is like to use, the settings it ended on,
and the raw measurements behind that, so the next model change starts from here
instead of from scratch. `home/local-ai.nix` holds the live settings. Halogen, the
engine in use, commits about 95 GB while it runs (Ky accepted that on 2026-11-18
for the quality and speed); the 80-90 GB budget below still applies to the
llama.cpp models.

## At a glance (2026-11-18)

**In use:** Qwen3.8 Flash Next on Halogen (the engine's own v2 checkpoint,
4.16 bpw). Fastest and best-behaved here: 3/3 coding, 6/8 coordinator on a
single turn, 3/4 multi-turn with no direct writes, and the most detailed image
description. It holds about 95 GB whenever it runs, so `Mod+Shift+H`
(`halogen-toggle`) stops it for games.
**Second pick:** Nemotron 3.5 Super VL through llama-swap, still installed and
pickable in `/model`, for when the memory has to stay lower.

| Model | Pick it for | Waiting on it | RAM left for everything else | Watch out for |
|---|---|---|---|---|
| **Halogen, v2 checkpoint, medium** (in use) | Everything: coordinator and workers | Small coding task: 16 to 40 s. Reads a 20K-token file in ~13 s | ~18 GB | One model only. ~95 GB held while it runs. Update is `docker pull`, not Omni Settings |
| **Flash Next IQ3_XXS, medium** (llama-swap) | Fallback in `/model` | Small coding task: 1 to 2 min. Reads a 20K-token file in 47 s | ~20 GB | Over the 80 GB budget. Leave effort at `medium`: its default (`xhigh`) overthinks |
| Flash Next IQ3_XXS, solo (1 slot of 256K) | One session at a time, no compaction | Small coding task: 1 to 2 min. Reads a 20K-token file in about 1 min | 19 to 22 GB | One slot, so parallel requests queue. A 120K-token turn reads 10 min — keep sessions near 60K |
| **Nemotron 3.5 Super VL** | Coordinator and workers within 80 GB | Small coding task: 3.5 to 6.5 min. Reads a 20K-token file in 63 s | ~40 GB | Slow at full reasoning. Tried `sudo` once |
| gpt-oss-120b + Qwen3.5-9B for images | Speed, if you can live without built-in vision | Small coding task: 1 to 2 min. Reads a 20K-token file in 23 s | not measured (77 GB loaded) | Vision comes from a small helper that made up details. Called `edit` directly once |
| Qwen3.8-27B, medium | Lots of free memory | Small coding task: about 3 min. Reads a 20K-token file in 81 s | ~58 GB | Slowest writer: about 13 tokens a second |
| Flash Next Q3_K_XL | Don't | n/a | ~10 GB | 93 GB: the file that ran out of memory |
| Qwen3.6 35B A3B | Don't | n/a | n/a | Broke every coordinator rule in real use |
| Qwen3-Coder-Next Q4_K_XL | Don't (tested 2026-10-29) | Answers ~1.7x faster than Flash Next | ~58 GB | Only 1/3 coding tasks right in every run. No vision, no thinking mode |

"Small coding task" is one of three functions checked by hidden tests. "RAM left"
is what was free with the model loaded and a test running.

## Each model in plain terms

### Qwen3.8 Flash Next on Halogen (in use, 2026-11-18)

The best setup tested on this machine. A dedicated engine for this one model,
run as a container and wired in as opencode's provider `halogen`; Llama.cpp's
GGUF build of the same model got three of three coding tasks right, and so does
this, but it is three to seven times faster to answer and it follows the
coordinator rules better (6/8 against 3/8 on a single turn).

Measured here: writing code at 55 to 86 tokens a second depending on context
depth (49.6 at 79K of context), reading at 940 to 1,644 tokens a second, and
98 tokens a second total across four parallel requests. Its 47.7 GiB n-gram
lookup table is read from disk through the page cache rather than held, which
is why `free` shows far less "used" than llama.cpp did: the weights are mapped
from the `.hgn` files (62 GiB pinned) and the table stays in cache. `MemFree`
is the number to watch (~18 GB), not the percentage or `MemAvailable`.

What it costs: about 95 GB is committed while it runs even when idle, it serves
only this model family, and its updates are `docker pull` by hand. The engine's
own README calls it a machine of its own; with the desktop also running, its
docs expect some prefill slowdown from the table falling out of cache.

Settings (`halogen-run` in `home/local-ai.nix`; starts with the session as the
user unit `halogen.service`):

- `HALOGEN_KV8=1` and `HALOGEN_KV_POOL_POSITIONS=262144`: an 8-bit KV cache,
  4.5 GiB for one 256K conversation instead of 7.7 (decode ~1.7% slower, more
  page cache left for the table).
- `HALOGEN_REASONING_EFFORT=medium`: the template's own default is `xhigh`,
  which overthinks.
- `HALOGEN_VISION_TOWER=/models/qwen38-flash-next-vision.hgn`: images are off
  without it (a 400 naming the flag).
- `HALOGEN_CACHE_DIR=/cache`: prompt cache on disk, so a conversation survives
  a restart instead of re-reading its history.
- `-u $(id -u):$(id -g)`: without it the cache and its files land root-owned in
  Ky's home; the engine runs fine unprivileged.
- Weights live in `~/halogen-models` (110 GiB), not in the nix store.

Raw numbers, 2026-11-18, v2 checkpoint, `medium`, KV8, one 256K pool:

| Check | Result |
|---|---|
| Coding, three tasks with hidden tests | 3/3, 15.8 / 31.9 / 39.9 s, 1,163 / 2,260 / 2,738 tokens |
| Coordinator, single turn | 6/8 (both misses read a file before delegating; same rule llama.cpp trips) |
| Coordinator, multi-turn | 3/4, no direct writes in any sequence |
| Vision, aisle frame | correct, 17.0 s |
| Decode, 300-word prose (`think` off) | 54.9 tok/s |
| Prefill, 21,447 tokens | 1,644 tok/s |
| Four parallel streams | 98.2 tok/s total |
| Two parallel thinking streams | 82.5 tok/s total |
| Load | 28 s cold |

GGUF mode was tried first and refused Ky's file: `blk.0.ffn_gate_exps.weight:
IQ2_S is not read by this engine`. Its supported types are `IQ4_NL`, `IQ4_XS`,
`IQ3_S`, `Q4_0`, `Q4_K`, `Q5_K`, `Q5_0`, `Q5_1`, `Q6_K`, `Q8_0` or wider, so
unsloth's UD mix of IQ3_XXS does not load. Its own docs also put GGUF mode at
~25 tok/s serial, no faster than llama.cpp.

### Qwen3.8 Flash Next, UD-IQ3_XXS (best results, not in use)

At `medium` effort it's the strongest model tested here. It solved all three
coding tasks in 41 to 110 seconds each, three to five times quicker than Nemotron.
As a coordinator it worked in parallel, changed nothing itself, and noticed when a
requested keybind already existed. Its image descriptions are the most observant
of any model: in the aisle frame it spotted a grey cube on the floor and a small
red object at the far end. It writes about as fast as Nemotron (28 tokens a second)
and reads long files faster.

The catch is memory. About 59 GB sits in GPU memory and another 27 GB in the
server process itself, which leaves roughly 20 GB for games, the editor and
everything else. Each token of context costs about 47 KB, so slots add up fast:
three 128K slots came to about 97 GB.

**In real use (night run, 2026-10-27 to 28, 2 then 3 slots of 64K):** it followed
every rule as a coordinator. It delegated 13 tasks, never edited anything itself,
ran each Godot check alone, and stayed out of `~/nixos-config`. But it got little
done. At 64K the workers compacted every 10 to 15 minutes on the game's
6,000-line scene file, lost their place, and re-read the same files. One went two
hours without an edit until Claude stopped it. One `explore` worker also ran Godot
and `pkill godot` against the rules. The run now uses 2 slots of 128K instead.
opencode can also send its own `reasoning_effort`, which beats the template
setting in llama.cpp, so the config sets it at the top level of each request too. Its chat template defaults to `xhigh` effort, which tells it to
second-guess everything: at that setting it ran out of room before answering two of
three tasks. `low` was too loose (it called `edit` directly once).

### Qwen3.8 Flash Next, UD-IQ3_XXS, 1 slot of 256K (solo config, 2026-10-29)

The same model and file, served as one slot of 262144 instead of two slots of
64K. Subagents were dropped from every profile, so the worker slots became
context: 256K keeps compaction from interrupting a session. Coding fitness is
unchanged — 3/3 at `medium` effort.

The big context costs prefill. A fixed 19K-token prompt reads at 312 to 355
tok/s (measured 3 times; one cold run gave 257) against 410 on the
2-slots-of-64K config — about 20% gone from the bigger configured context
alone. Decode is 26.1 tok/s (28.2 on 2 slots), and four requests at once
total 22.9 tok/s: one slot, so they queue. RAM left is 19 to 22 GB with up to
~156K tokens of cache in use.

What Ky waits for is the read before the model types: a 30K-token turn takes
1.6 min, 60K 3.6 min, 120K 10.1 min, 156K 15.2 min, because prefill falls from
~330 tok/s at 30K to 172 at 156K. 256K is headroom to keep, not headroom to
use — keep sessions nearer 60K by writing less.

A pitfall this run found: a bare `llama-server` lacks llama-swap's
`reasoning_effort = medium`, and at the template default (`xhigh`) Flash Next
spent the whole 12K-token task budget thinking and emitted no code, which
reads as a false 0/3. Measure through llama-swap, or pass
`--reasoning-effort medium`.

```
one slot of 262144, output 16384, -ctv q8_0, mmproj-F16.gguf attached
request: reasoning_effort "medium" and chat_template_kwargs {"reasoning_effort": "medium"}
```

Measured 2026-10-29 through llama-swap with the committed 1-slot config;
harness in `local-ai-bench/` plus a prefill scaling sweep.

### Nemotron 3.5 Super VL (in use)

The careful one. In every coordinator test it handed changes to subagents, refused
Warpledge's shared files, ignored a "just use sed" shortcut, and caught a worker
that claimed it was done without changing anything. It solved all three coding
tasks, but at full reasoning each took 3.5 to 6.5 minutes. With MTP drafting it
writes about 28 tokens a second, so a screen of code (about 500 tokens) takes
around 18 seconds. Reading a long file is slower than Flash Next. It uses 72 GB of
GPU memory, inside the 80 GB budget. A run at `medium_effort` for a fairer
comparison with Flash Next is under way.

### gpt-oss-120b with Qwen3.5-9B for images (tested, not in use)

The fastest setup by a wide margin: about 45 tokens a second, and it reads a
20K-token file in about 23 seconds. It solved two of three coding tasks in one to
two minutes each and coordinated well, but called `edit` directly once, which
opencode would have blocked. It can't see images, so a small Qwen3.5-9B loads
beside it for that. The helper took 15 seconds per image with thinking off but made
details up, or 47 seconds and accurate with thinking on. Both loaded take 77 GB.

### Qwen3.8-27B (tested, not in use)

Fits easily at 45 GB and leaves almost 60 GB free. At `medium` effort it solved all
three coding tasks and coordinated well in the single-turn tests, but it writes only
about 13 tokens a second even with MTP, so each task took around three minutes.
At its default `xhigh` effort it never finished a task.

### Qwen3.8 Flash Next, UD-Q3_K_XL (don't use)

The file that was in use before 2026-10-27. Same model as the IQ3_XXS above, but
93 GB in all, which left 10 GB free and ran out of memory. Delete it once the
IQ3_XXS file is settled.

### Qwen3-Coder-Next, UD-Q4_K_XL (tested 2026-10-29, not adopted)

`unsloth/Qwen3-Coder-Next-GGUF`, 49.6 GB, kept on disk at
`~/.lmstudio/models/unsloth/Qwen3-Coder-Next-GGUF/`. Served once for testing:
1 slot of 262144.

```
-fa on -ngl 99 --load-mode none -ub 2048 -ctv q8_0 --jinja
```

No mmproj: the repo ships none, so no vision.

It is quick. Decode 43.4 to 44.7 tok/s, steady across runs; 628 tok/s prefill
over 18,815 tokens (708 instantaneous mid-prompt); 4 parallel requests total
42.0 to 42.2 tok/s; 58 GB of RAM left. In plain terms every answer arrives
~1.7x faster and long prompts read ~2x faster than Flash Next.

But it got fewer tasks right on the first pass: 1/3 on the coding tasks in
each of three runs, and a different task failed each time (`retry_after`
passed, though it accepts `'+3'` via `int()`, the known miss; `lazy_chunks`
failed 3/3, raising on the first `next()` instead of at call time;
`safe_join` passed 2/3). An agentic loop pays for a miss in extra turns.
Coordinator scenarios 2/8: it read files itself instead of delegating, and
one run took a direct shell write under bait — recorded before delegation was
dropped from every profile. No thinking mode at all: its chat template has
zero `enable_thinking` support, so `reasoning_effort` does nothing to it.
Frame review is impossible without vision, so a gamedev agent could not check
a rendered frame. The full harness ran in 2m19s, against Flash Next's coding
tasks at 41 to 110 s each.

Verdict as recorded: not adopted; Flash Next stays the coding model. Revisit
if a run of misses costs more than the speed buys.

### Qwen3.6 35B A3B (dropped 2026-10-27)

Fast (about 46 tokens a second) and small (37 GB), but as a coordinator it ignored
its rules: it never delegated, edited files through the shell after edits were
blocked, changed git remotes, ran garbage collection unasked, wrote to Warpledge's
shared files, and wiped uncommitted game work with `git checkout HEAD -- .`. Ky
found its code poor too.

### Earlier models (2026-10-25, from commit messages)

- **DeepSeek V4 Flash:** UD-IQ3_XXS, 97 GiB, 13B active. Its DSpark drafter (10 GiB)
  nearly doubled generation but left about 1 GiB of RAM free. Thinking capped at
  4096 tokens.
- **gpt-oss-120b (59 GiB):** read input about 3 times faster than DeepSeek. Text only.
- **Ornith 1.5 35B A3B:** replaced by the two above the same day.

## Settings to copy

All need llama.cpp 0.7.0 or newer (built in `local-ai.nix`) and load from
`~/.lmstudio/models/`. Every one here runs fully on the GPU (`-fa on -ngl 99`).

**Nemotron 3.5 Super VL** (`unsloth/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-GGUF`,
UD-Q3_K_XL plus `mmproj-BF16.gguf`):

```
-np 3 -kvu --kv-unified-per-slot 65536 -fa on -ngl 99 --load-mode none -ub 2048
-ctk f16 -ctv f16 --spec-type draft-mtp --top-k 0 --min-p 0 --mmproj …/mmproj-BF16.gguf
request: temperature 1.0, top_p 0.95
coordinator: chat_template_kwargs {"enable_thinking": true}
workers:     chat_template_kwargs {"enable_thinking": true, "medium_effort": true}
```

opencode: context 65536, output 16384, so it compacts near 48K.

**Qwen3.8 Flash Next** (`unsloth/Qwen3.8-Flash-Next-GGUF`, UD-IQ3_XXS plus
`mmproj-F16.gguf`):

```
-np 2 -kvu --kv-unified-per-slot 131072 -fa on -ngl 99 --load-mode none -ub 2048
-ctk f16 -ctv q8_0 --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0 --mmproj …/mmproj-F16.gguf
request: reasoning_effort "medium" and chat_template_kwargs {"reasoning_effort": "medium"}
```

A request that asked for `low` and one that asked for `xhigh` both thought about
the same amount (1,720 and 1,886 tokens) once llama-swap set the top-level field.

The q8_0 V cache measured about 17% faster prompts at 32K with perplexity within
error. `reasoning_effort` takes `xhigh` (the default), `medium` or `low`; `high`
means `xhigh`.

**gpt-oss-120b** (`ggml-org/gpt-oss-120b-GGUF`, MXFP4):

```
-np 3 -kvu --kv-unified-per-slot 65536 -fa on -ngl 99 --load-mode none -ub 2048
-ctk f16 -ctv f16 --temp 1.0 --top-p 1.0 --top-k 0 --min-p 0
request: chat_template_kwargs {"reasoning_effort": "high"}   (low, medium or high)
```

**Qwen3.5-9B vision helper** (`unsloth/Qwen3.5-9B-GGUF`, UD-Q4_K_XL plus
`mmproj-F16.gguf`, fetched from Hugging Face because LM Studio wouldn't):

```
-np 1 -c 32768 -fa on -ngl 99 --temp 0.7 --top-p 0.8 --top-k 20 --min-p 0 --mmproj …
```

**Qwen3.8-27B** (`unsloth/Qwen3.8-27B-GGUF`, UD-Q6_K_XL plus `mmproj-F16.gguf`):

```
-np 3 -kvu --kv-unified-per-slot 65536 -fa on -ngl 99 -ub 2048 --spec-type draft-mtp
--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0
request: chat_template_kwargs {"reasoning_effort": "medium"}
```

**Qwen3.6 35B A3B** (`unsloth/Qwen3.6-35B-A3B-GGUF`, UD-Q4_K_XL, about 25% faster
than Q8 here): 4 slots of 128K with `-kvu`, f16 cache (only 10 of its 40 layers keep
one, so 4 x 128K is about 11 GB). Coordinator temperature 0.6, top_p 0.95, top_k 20;
workers with thinking off at 0.7, 0.8, presence penalty 1.5.

**Flash Next as first set up** (UD-Q3_K_XL): one slot of 128K, same cache types and
sampling as above. 68 GB GPU memory plus 36 GB in the server process.

## Raw data

All runs on 2026-10-27, llama.cpp 0.7.0, one model at a time on port 8095. Speeds
are tokens per second with thinking on unless noted. Memory is GPU memory
(`mem_info_gtt_used` plus `mem_info_vram_used`) plus the server process where it
holds part of the model.

### Speed and memory

| Model, settings | Memory | RAM free | 1 req | 2 req | 3 req | 4 req | Prompt (19K) |
|---|---|---|---|---|---|---|---|
| Nemotron, 3 slots, MTP | 72 GB | ~40 GB | 28.4 | 29.0 | 24.6 | 19.6 | 306 |
| Nemotron, 4 slots, MTP | 74 GB | | | | | | |
| Nemotron, 4 slots, no MTP | 66 GB | | 18.6 | 26.0 | 30.2 | 30.9 | 306 |
| Flash Next IQ3_XXS, 2 slots of 64K | 59 + 27 GB | 19 to 20 GB | 28.2 | 39.2 | | 38.4 | 410 |
| Flash Next IQ3_XXS, 3 slots of 128K | 71 + 26 GB | 14 GB | | | | | |
| Flash Next Q3_K_XL, 2 slots | 66 + 27 GB | 10 GB | 25.1 | 32.4 | | 34.8 | 407 |
| Qwen3.8-27B, 3 slots, MTP | 45 GB | 58 to 59 GB | 13.4 | 20.5 | | 17.4 | 235 |
| gpt-oss-120b, 3 slots | 69 GB | | 45.1 | | | 52.7 | 849 |
| gpt-oss + Qwen3.5-9B helper | 77 GB | | | | | | |
| Qwen3.6 35B A3B, 4 slots of 128K | ~37 GB | | ~46 | | | | 600 to 1,600 |
| Flash Next IQ3_XXS, 1 slot of 256K | 59 + ~54 GB | 19 to 22 GB | 26.1 | | | 22.9 | 312 to 355 |
| Qwen3-Coder-Next Q4_K_XL, 1 slot of 256K | 50 GB | ~58 GB | 43.4 | | | 42.1 | 628 |

- Nemotron's MTP accepted 84% of drafts on code and about 52% on prose (21.1 tok/s
  alone, thinking off). MTP wins with one or two requests and loses from three, so
  the config runs 3 slots: one coordinator, two workers.
- Qwen3.8-27B's MTP accepted 39 to 52% of drafts.
- Qwen3.6's prompt reading fell to 310 tok/s for a 106K prompt with 3 other requests
  running: one turn took 6 minutes.
- Nemotron loads in about 25 seconds.

### Coding (three tasks with hidden tests, 12,000-token cap)

| Model, effort | Score | Time per task | Tokens per task |
|---|---|---|---|
| Nemotron, full | 3/3 | 202 to 399 s | 3,582 to 7,164 |
| Nemotron, `medium_effort` | pending | | (726 against 2,283 on one prompt) |
| Flash Next IQ3_XXS, medium | 3/3 | 41 to 110 s | 1,077 to 2,932 |
| Flash Next IQ3_XXS, low | 2/3 | 27 to 77 s | 692 to 2,049 |
| Flash Next IQ3_XXS, xhigh | 1/3 | 333 to 463 s | 8,728; two hit the cap |
| Flash Next Q3_K_XL, xhigh | 0/3 | 502 to 511 s | all hit the cap |
| Qwen3.8-27B, medium | 3/3 | 172 to 198 s | 3,206 to 3,648 |
| Qwen3.8-27B, xhigh | 0/3 | 801 to 842 s | all hit the cap |
| gpt-oss-120b, high | 2/3 | 48 to 117 s | 2,025 to 4,903 |

gpt-oss missed that `lazy_chunks` must raise on the call rather than on the first
`next()`. Flash Next at low missed `retry_after`.

### Coordinator checks

Single-turn scores count a first move that reads before delegating as a miss, so
the multi-turn run is the one to trust.

| Model, effort | Single turn | Multi-turn | Notes |
|---|---|---|---|
| Nemotron, full | 4/8 | passed | no writes; caught a fake worker; one `sudo journalctl` |
| Flash Next IQ3_XXS, medium | 3/8 | passed | no writes; found the existing bind; split work both times |
| Flash Next IQ3_XXS, low | 6/8 | one slip | called `edit` directly once |
| Flash Next IQ3_XXS, xhigh | 3/8 | passed | no writes |
| Flash Next Q3_K_XL, xhigh | 4/8 | passed | no writes; saw through fake workers; stray probing (`cd /root`, `git -C /`) |
| Qwen3.8-27B, medium | 6/8 | passed the split twice | first multi-turn run crashed on a slow `find /`; rerun under way |
| Qwen3.8-27B, xhigh | 2/8 | passed | |
| gpt-oss-120b, high | 3/8 | one slip | called `edit` directly once; split work across three subagents |

### Vision (aisle frame from the game's test baseline)

| Model | Time | Result |
|---|---|---|
| Nemotron | 72 s | correct: blue racking, boxes, fluorescent lights, no text; missed the crosshair |
| Flash Next IQ3_XXS, medium | 32 s | correct |
| Flash Next Q3_K_XL, xhigh | | most observant: grey cube on the floor, red object at the end |
| Qwen3.8-27B | | correct |
| Qwen3.5-9B helper, thinking off | 15 s | mostly right; made up "flickering" lights, guessed Unity |
| Qwen3.5-9B helper, thinking on | 47 s | correct, noted the flat untextured shading |

### Published comparison (NVIDIA's Nemotron model card, vendor numbers)

Nemotron trails Flash Next on most coding and agent rows (Terminal-Bench 2.1: 66.7
against 85.8; SWE-bench Pro: 51.8 against 60.4) and beats Qwen3.5-122B-A10B on
coding and agent rows, though not on vision.

## How models are tested

The scripts in `local-ai-bench/` run against llama-swap on 8090, so the model's own
params and template switches apply; unload the other model first so the two don't
share memory. If a server must be started by hand, pass `--reasoning-effort` for
that model or its numbers are measuring the wrong settings.
`run.sh LABEL SERVER MODEL "FLAGS" 'BENCH_EXTRA' [IMAGE]` does the whole round for
one model (load, memory, all checks, unload) and writes results to `$BENCH_OUT`:

- `bench.py URL MODEL LABEL [IMAGE]`: generation and prompt speed, 4 requests at
  once, a coordinator tool-discipline test (delegate an edit, split two tasks,
  refuse a shared file, resist a "just use sed" request), three coding tasks
  checked by hidden tests (`retry_after`, `safe_join`, `lazy_chunks`), and a vision
  description of the game's `tests/baseline/pose_05_aisle.png`.
- `followup.py URL MODEL LABEL`: the same coordinator prompts over several turns,
  answering `read` and read-only shell calls for real.
- `speed.py URL` and `par2.py URL N`: generation speed alone and with N thinking
  requests at once.
- `vision.py URL IMAGE`: the frame description with thinking off, then on.

`BENCH_EXTRA` passes the model's own sampling and template switches, for example
`'{"temperature":1.0,"top_p":0.95,"chat_template_kwargs":{"reasoning_effort":"medium"}}'`.
Check a model's chat template for an effort switch before testing: Flash Next and
Qwen3.8-27B default to `xhigh`, which made both look far worse than they are.
