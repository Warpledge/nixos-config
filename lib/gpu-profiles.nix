#=====================================================================#
# GPU PROFILES FOR LOCAL AI MODELS
#=====================================================================#
#- What a machine's localModels.profile can pick. `defaults` are tuning
#- fields (as in local-models.nix's `tuned`) every model gets on that GPU;
#- a model's own `tuned.<profile>` values and the machine's localModels.models
#- go on top. Omni Settings matches `pciIds` (vendor:device, `lspci -nn`)
#- to suggest a profile, and sizes its fit estimate from `memory` and
#- `headroomMB`. lib/local-ai.nix applies them.
{
  #--- 16GB discrete card; the catalog's tuned.rx-9070-xt values were measured on it
  "rx-9070-xt" = {
    name = "Radeon RX 9070 XT (16GB)";
    pciIds = ["1002:7550"];
    memory = "discrete";
    headroomMB = 2048;
    defaults = {};
    note = "Experts that don't fit in VRAM go to RAM; tuned values exist for the catalog models.";
  };
  #--- Ryzen AI Max (Radeon 8060S): RAM and VRAM are one pool, so offloading
  #--- experts to RAM gains nothing. Defaults from kyuz0/amd-strix-halo-toolboxes
  "strix-halo" = {
    name = "Ryzen AI Max / Strix Halo (Radeon 8060S)";
    pciIds = []; # Not confirmed yet: fill in from `lspci -nn` on one
    memory = "unified";
    headroomMB = 4096;
    defaults = {
      gpuLayers = "all";
      loadMode = "none";
    };
    note = "Models over half the memory need GPU Shared Memory raised (localModels.gpuSharedGB).";
  };
}
