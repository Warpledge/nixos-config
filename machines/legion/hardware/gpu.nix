#=====================================================================#
# HYBRID GPU CONFIGURATION (AMD IGPU + NVIDIA DISCRETE)
#=====================================================================#
{
  pkgs,
  config,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Drivers & Packages
  #--------------------------------------------------------------------#
  #--- Load AMD GPU drivers
  #--- hardware.nvidia sets nvidia-drm modeset/fbdev, PreserveVideoMemoryAllocations
  #--- and the nouveau blacklist itself
  boot.initrd.kernelModules = ["amdgpu"];

  #--- hardware.nvidia below does nothing without "nvidia" here, Wayland
  #--- included; X itself stays off (system/desktop/input.nix)
  services.xserver.videoDrivers = ["nvidia"];

  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      #--- Mesa is the default package; hardware.nvidia adds nvidia-vaapi-driver
      #--- and the EGL Wayland/GBM platforms
      extraPackages = with pkgs; [
        libvdpau-va-gl # VDPAU driver with OpenGL/VA-API backend
        rocmPackages.clr.icd # AMD GPU compute runtime
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libvdpau-va-gl
      ];
    };
    nvidia = {
      moduleParams.nvidia.NVreg_UsePageAttributeTable = 1; # CPU Page Attribute Table
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      nvidiaSettings = false;
      prime = {
        #--- GPU switching offload - AMD iGPU for display, NVIDIA for compute
        offload.enable = true;
        offload.enableOffloadCmd = true; # The nvidia-offload command
        #--- NVIDIA GeForce RTX 4070 Max-Q
        nvidiaBusId = "PCI:1:0:0";
        #--- AMD Radeon 680M (integrated)
        amdgpuBusId = "PCI:6:0:0";
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- Environment & Packages
  #--------------------------------------------------------------------#
  environment = {
    variables = {
      #--- Use AMD iGPU for display (Niri compatibility)
      LIBVA_DRIVER_NAME = "radeonsi";
      #--- Global offload, left off as in wm/niri.nix: it puts every EGL and
      #--- Vulkan app on the 4070; nvidia-offload routes one app
      # __NV_PRIME_RENDER_OFFLOAD = "1";
      # __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      # NOTE: CUDA_PATH disabled — re-enable if CUDA is needed
      # CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    };

    systemPackages = with pkgs; [
      nvtopPackages.full # GPU monitor, AMD and NVIDIA (v3d is Raspberry Pi only)
      amdgpu_top # 680M

      #--- Video Acceleration/Decoding
      libva # Video Acceleration API
      libva-utils # Tools for VA-API

      #--- Vulkan Development/Debug Tools
      vulkan-tools # Vulkan development utilities
      vulkan-loader # Runtime loader for Vulkan applications
      vulkan-validation-layers # Validation and debugging for Vulkan
      vulkan-extension-layer # Additional Vulkan features

      # NOTE: CUDA packages disabled — re-enable if CUDA is needed
      # cudaPackages.cudatoolkit
      # cudaPackages.cudnn
      # cudaPackages.nccl
    ];
  };

  # NOTE: CUDA cache disabled — re-enable alongside CUDA packages if needed
  # nix.settings = {
  #   substituters = ["https://cuda-maintainers.cachix.org"];
  #   trusted-public-keys = [
  #     "cuda-mantainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
  #   ];
  # };
}
