#=====================================================================#
# GPU SHARED MEMORY (localModels.gpuSharedGB IN THE MACHINE'S SETTINGS)
#=====================================================================#
#- How much system RAM an APU's GPU may use (GTT), for local models on
#- unified-memory chips like Strix Halo. Values as kyuz0/amd-strix-halo-
#- toolboxes sets them: gttsize in MiB, ttm.pages_limit in 4 KiB pages.
{machine, ...}: let
  gb = machine.localModels.gpuSharedGB;
in {
  boot.kernelParams = [
    "amdgpu.gttsize=${toString (gb * 1024)}"
    "ttm.pages_limit=${toString (gb * 262144)}"
  ];
}
