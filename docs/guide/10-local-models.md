# Local AI Models

llama-swap runs AI models on your own computer and hands them to opencode, Zed and Open WebUI. Omni Settings' Local Models page (AI tab) sets how each model loads on your GPU, shows whether it fits, and tests it. It shows once llama-swap is turned on (Local AI, Tools).

## Getting a model

Download models in LM Studio (its Discover tab). They land in `~/.lmstudio/models`, and the Local Models page lists every file there that no model uses yet under **Downloaded in LM Studio**. Click **Add**, choose whether it's for coding or chat, and give it a name. After Apply, turn it on under Local AI, Models.

The models the config ships with are listed under **Models** whether or not you've downloaded them. One that isn't downloaded shows in yellow.

## What fits

Your GPU's memory (VRAM) has to hold the model's weights, its context, and some working space. Other apps hold VRAM too: the desktop, browsers, Discord, and an animated wallpaper (about 1 GB). Open a model and the bar at the top shows:

- grey: what other apps use right now
- coloured: what the model needs. It's your accent colour when it fits, yellow when it fits with little room left, and red when it's too big

The numbers are an estimate read from the model file. **Test These Settings** loads the model for real and reports what it used.

## The settings

You rarely need more than the presets. Each one changes the settings below it, and nothing is saved until you click Save and then Apply.

| Preset | What it does |
| --- | --- |
| Measured | The values tested on your GPU profile, where the model has some |
| Max Speed | Keeps the context and puts as much on the GPU as fits |
| Max Context | The longest context that still fits, moving more into RAM, so it replies slower |
| Auto | Leaves the split to llama.cpp, which fits the model when it loads |

To fine-tune instead, change one setting at a time and test after each:

- **Context** is how much the model holds at once: your question, the files it reads and its answer. Coding agents need a lot (64K or more); a chat is fine with 32K. More context takes more VRAM.
- **Context Cache** sets how precisely the context is stored. Half Size is the usual choice: it barely changes answers and fits twice the context of Full. Quarter Size can make long answers worse.
- **Layers on the GPU**: All is fastest when it fits. Fewer layers move the rest onto the CPU, which is far slower. Auto lets llama.cpp decide.
- **Experts in RAM** shows only for mixture-of-experts models (names with "A3B", "A4B" and so on). Each layer's experts can live in RAM while the rest stays on the GPU. Raise it until the model fits; each step frees VRAM for context, and replies get a little slower.
- **Prompt Batch** is how much of a long prompt it reads per step. 2048 reads files faster than the default 512, and needs a little more VRAM.
- **Prompt Cache in RAM** keeps earlier conversations in RAM so going back to one doesn't reread it. Lower it if RAM runs short.

A good routine: pick **Max Speed**, test, and look at the speed. If you want more context, raise Context, raise Experts in RAM until the bar fits again, and test once more.

## Testing

**Test These Settings** loads the model on its own, sends a short prompt and reports:

- how fast it writes (tokens a second; 20 or more feels quick)
- how fast it reads a prompt
- the most VRAM it used, and how much more RAM

It unloads whatever llama-swap had loaded first, so don't run it while an app is mid-answer. llama-swap loads its model again the next time an app asks. The models list keeps each model's last result while its settings stay the same.

Close what you don't need before testing, the animated wallpaper included, so the numbers match how you'll use the model.

## GPU profile

The profile at the top tells the models which tested values to use. The page notices your GPU and offers the matching one. With none, llama.cpp fits each model itself, which works on any GPU.

On a chip where the GPU shares the computer's RAM (Ryzen AI Max / Strix Halo), **GPU Shared Memory** sets how much of it the GPU may use. By default that's about half. Leave 4 to 8 GB for the system: 120 on a 128 GB machine, 56 on 64 GB. It takes effect after a restart.

Changes on this page are for this computer only. Another computer keeps its own.
