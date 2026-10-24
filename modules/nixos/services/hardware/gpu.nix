#=====================================================================#
# GRAPHICS DRIVERS (gpu.* IN THE MACHINE'S SETTINGS.NIX)
#=====================================================================#
#- Loaded when gpu.type is set; desktop and laptop leave it null and set up
#- their cards in their own hardware/gpu.nix. NVIDIA details beyond this:
#- https://wiki.nixos.org/wiki/NVIDIA
{
  config,
  lib,
  pkgs,
  machine,
  ...
}: let
  inherit (machine) gpu;
  has = vendor: lib.elem vendor (lib.splitString "+" gpu.type);
  hybrid = lib.hasInfix "+" gpu.type;
in {
  config = lib.mkMerge [
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # 32-bit games, Wine and Proton
      };
    }

    #--- AMD: Mesa already carries the Vulkan and VA-API drivers
    (lib.mkIf (has "amd") {
      hardware.amdgpu.initrd.enable = true; # Early display for the boot splash
      environment.systemPackages = [pkgs.amdgpu_top];
    })

    #--- Intel
    (lib.mkIf (has "intel") {
      hardware.graphics.extraPackages = [pkgs.intel-media-driver]; # VA-API video decode
    })

    #--- NVIDIA: videoDrivers is what turns hardware.nvidia on, Wayland included
    (lib.mkIf (has "nvidia") {
      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        modesetting.enable = true;
        # The open kernel module needs Turing (GTX 16xx, RTX) or newer
        open = !gpu.nvidiaLegacy;
        package = with config.boot.kernelPackages.nvidiaPackages;
          if gpu.nvidiaLegacy
          then legacy_580
          else stable;
        nvidiaSettings = false;
      };
    })

    #--- Hybrid laptops: the integrated chip drives the screen; run a program
    #--- on the NVIDIA one with `nvidia-offload <program>`
    (lib.mkIf hybrid {
      hardware.nvidia.prime =
        {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          inherit (gpu) nvidiaBusId;
        }
        // (
          if has "amd"
          then {amdgpuBusId = gpu.integratedBusId;}
          else {intelBusId = gpu.integratedBusId;}
        );
    })
  ];
}
