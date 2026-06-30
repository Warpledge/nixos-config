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
  boot = {
    initrd.kernelModules = ["amdgpu"];
    blacklistedKernelModules = ["nouveau"]; # Prevent nouveau from loading
    kernelParams = [
      "nvidia-drm.modeset=1" # Enable direct mode setting for better Wayland support
      "nvidia_drm.fbdev=1" # Enable framebuffer device support
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Keep video memory allocations across suspend/resume
      "nvidia.NVreg_UsePageAttributeTable=1" # Enable CPU Page Attribute Table for better memory management
    ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        #--- NVIDIA packages
        nvidia-vaapi-driver # Video acceleration for NVIDIA GPUs
        libva-vdpau-driver # Bridge between VA-API and VDPAU for video decoding
        libvdpau-va-gl # VDPAU driver with OpenGL/VA-API backend
        egl-wayland # EGL support for Wayland
        nv-codec-headers-12 # Headers for NVIDIA video codec SDK

        #--- AMD packages
        mesa # Open source 3D graphics library (includes AMD drivers)
        rocmPackages.clr.icd # AMD GPU compute runtime

        #--- Common packages
        vulkan-loader # Vulkan driver loader
        vulkan-validation-layers # Debug/development tools for Vulkan
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva-vdpau-driver
        mesa
        libvdpau-va-gl
      ];
    };
    nvidia = {
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      nvidiaSettings = false;
      prime = {
        #--- GPU switching offload - AMD iGPU for display, NVIDIA for compute
        offload.enable = true;
        offload.enableOffloadCmd = true;
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
      GBM_BACKEND = "mesa";
      #--- Let applications detect both GPUs
      #--- Enable NVIDIA offload for CUDA applications
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      # NOTE: CUDA_PATH disabled — re-enable if CUDA is needed
      # CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    };

    systemPackages = with pkgs; [
      nvtopPackages.v3d # GPU monitoring tool (supports both AMD and NVIDIA)

      #--- Video Acceleration/Decoding
      libva # Video Acceleration API
      libva-utils # Tools for VA-API
      libva-vdpau-driver # VDPAU backend for VA-API

      #--- Vulkan Development/Debug Tools
      vulkan-tools # Vulkan development utilities
      vulkan-loader # Runtime loader for Vulkan applications
      vulkan-validation-layers # Validation and debugging for Vulkan
      vulkan-extension-layer # Additional Vulkan features

      # NOTE: CUDA packages disabled — re-enable if CUDA is needed
      # cudaPackages.cudatoolkit
      # cudaPackages.cudnn
      # cudaPackages.nccl

      #--- Helper script for NVIDIA offload
      (pkgs.writeShellScriptBin "nvidia-offload" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec "$@"
      '')
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
