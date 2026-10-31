#=====================================================================#
# LOCAL AI MODELS FOR ONE MACHINE
#=====================================================================#
#- The catalog (local-models.nix) plus the models a machine's localModels
#- block adds, each with its llama.cpp flags for that machine's GPU profile
#- (gpu-profiles.nix). Tuning comes from, last wins: the profile's defaults,
#- the model's tuned.<profile>, then localModels.models.<id>. With no offload
#- set, llama-server fits the model itself, leaving fitTarget MB free.
#- Takes the machine's merged localModels setting.
{
  lib,
  localModels,
}: let
  catalog = import ./local-models.nix;
  profiles = import ./gpu-profiles.nix;
  inherit (localModels) profile models;
  gpu =
    if profile == null
    then null
    else profiles.${profile};

  #--- Fields a machine may change on any model; kept in step with lib/settings.nix
  tuningFields = ["context" "cache" "gpuLayers" "cpuMoe" "batch" "cacheRam" "fitTarget" "loadMode"];
  #--- What a machine-added model starts from
  addedDefaults = {
    context = 32768;
    args = [];
    think = {};
    fast = null;
  };

  #--- Models the machine adds, by category ("code" or "chat")
  added = category:
    lib.mapAttrs (_: model: addedDefaults // removeAttrs model ["category"])
    (lib.filterAttrs (id: model: !(catalog.code ? ${id} || catalog.chat ? ${id}) && model.category == category) models);

  #--- llama-server flags for one model's final tuning
  flags = t: let
    # gpuLayers "auto" leaves the layer count to llama-server's fit
    fixed = t ? cpuMoe || (t ? gpuLayers && t.gpuLayers != "auto");
    fit =
      t.fitTarget or (
        if fixed
        then null
        else if gpu == null
        then 2048
        else gpu.headroomMB
      );
  in
    lib.optional (t ? gpuLayers && t.gpuLayers != "auto") "-ngl ${toString t.gpuLayers}"
    ++ lib.optional (t ? loadMode) "--load-mode ${t.loadMode}"
    ++ lib.optional (t ? cpuMoe) "--n-cpu-moe ${toString t.cpuMoe}"
    ++ lib.optional (t ? batch) "-ub ${toString t.batch}"
    ++ lib.optional (t ? cacheRam) "--cache-ram ${toString t.cacheRam}"
    ++ lib.optional (fit != null) "--fit-target ${toString fit}";

  resolve = id: model: let
    own = models.${id} or {};
    measured =
      (
        if gpu == null
        then {}
        else gpu.defaults
      )
      // (
        if profile == null
        then {}
        else model.tuned.${profile} or {}
      );
    # The machine's gpuLayers "auto" hands offload back to llama-server's fit
    t =
      (
        if own.gpuLayers or null == "auto"
        then removeAttrs measured ["gpuLayers" "cpuMoe"]
        else measured
      )
      // lib.getAttrs (lib.filter (f: own ? ${f}) tuningFields) own;
  in
    removeAttrs model ["tuned" "cpuMoe" "gpuLayers" "batch" "cacheRam" "fitTarget" "loadMode"]
    // {
      context = t.context or model.context;
      args = flags t ++ model.args;
    }
    // lib.optionalAttrs (t ? cache) {inherit (t) cache;};
in {
  code = lib.mapAttrs resolve (catalog.code // added "code");
  chat = lib.mapAttrs resolve (catalog.chat // added "chat");
  inherit (catalog) edit;
}
