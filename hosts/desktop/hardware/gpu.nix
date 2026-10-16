#=====================================================================#
# AMD GPU CONFIGURATION (RX 9070 XT)
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Drivers & Packages
  #--------------------------------------------------------------------#
  #--- Load the AMDGPU kernel module early for proper hardware initialization
  boot.initrd.kernelModules = ["amdgpu"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libva # Video Acceleration API for hardware-accelerated video decode/encode
      libva-vdpau-driver # VAAPI driver that uses VDPAU as backend
      libvdpau-va-gl # VDPAU driver with VA-GL backend
      rocmPackages.clr.icd # AI Acceleration for AMD GPUs
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      libva-vdpau-driver # 32-bit VAAPI driver that uses VDPAU as backend
      libvdpau-va-gl # 32-bit VDPAU driver with VA-GL backend
    ];
  };
  environment.systemPackages = with pkgs; [
    vulkan-tools # For vulkaninfo
    libva-utils # For vainfo
  ];

  #--- ensures that the amdgpu kernel module is loaded in stage 1
  hardware = {
    amdgpu = {
      initrd.enable = true; # Load AMDGPU driver in initrd for early GPU access
      opencl.enable = true;
    };
    enableRedistributableFirmware = true; # Proprietary firmware blobs
    cpu.amd.updateMicrocode = true;
  };

  #--------------------------------------------------------------------#
  #-- Tweaks
  #--------------------------------------------------------------------#

  environment.variables = {
    #--- Prevents AMDVLK from being picked for games—critical for performance
    AMD_VULKAN_ICD = "RADV";

    #--- Force RADV; both 64- and 32-bit ICDs so 32-bit Proton games work
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json";

    #--- RDNA 3 specific tweaks
    DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 = "1";

    #--- Disable shader disk cache size limit (useful for large game libraries)
    AMD_SHADER_DISK_CACHE_SIZE = "10737418240"; # 10GB shader cache
  };

  #--- Kernel Tweaks
  boot = {
    kernelParams = [
      #--- AMD CPU Optimizations
      "amd_pstate=active" # Enable AMD P-state CPU scaling driver
      "amd_pstate.shared_mem=1" # Enable shared memory for P-state (Zen 3+)
      "amd_prefcore=enable" # Enable preferred core detection
      "amd_iommu=on" # Enable AMD IOMMU ("force" can cause issues)
      "clocksource=tsc" # Use TSC for better gaming performance
      "tsc=reliable" # Trust TSC clocksource
      "iommu=pt" # Passthrough mode for better performance

      #--- Gaming Performance Optimizations
      "transparent_hugepage=always" # Enable transparent huge pages
      "split_lock_detect=off" # Disable split lock detection

      #--- AMD GPU Optimizations
      "amdgpu.gpu_recovery=1" # Enable GPU recovery from hangs
      "amdgpu.dpm=1" # Enable dynamic power management
    ];
  };
}
