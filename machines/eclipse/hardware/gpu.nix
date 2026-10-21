#=====================================================================#
# AMD GPU CONFIGURATION (RX 9070 XT)
#=====================================================================#
{
  lib,
  machine,
  pkgs,
  ...
}: {
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
    #--- Force RADV; both 64- and 32-bit ICDs so 32-bit Proton games work
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json";
  };

  #--- Kernel Tweaks
  boot = {
    kernelParams = [
      #--- AMD CPU Optimizations
      "amd_pstate=active" # Enable AMD P-state CPU scaling driver
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

  #--------------------------------------------------------------------#
  #-- GPU Tuning (LACT)
  #--------------------------------------------------------------------#
  #--- Overdrive unlocks LACT's voltage, clock and fan-curve controls. The mask
  #--- is the kernel default 0xfff7bfff plus the overdrive bit 0x4000; the
  #--- module's default mask also changes GFXOFF, stutter mode and GFX DCS
  services.lact.enable = true;
  hardware.amdgpu.overdrive = {
    enable = true;
    ppfeaturemask = "0xfff7ffff";
  };

  #--------------------------------------------------------------------#
  #-- DMS GPU Widget
  #--------------------------------------------------------------------#
  #--- For every user, under niri. The variant pins this GPU by PCI
  #--- address; the bar widget id in settings.json (amdGpuMonitor:<id>) must match it.
  home-manager.users =
    lib.mapAttrs (_: _: {
      programs.dank-material-shell.plugins.amdGpuMonitor.enable = true;
      #--- Through dms.pluginSettings, which both WMs' DMS modules read
      dms.pluginSettings.amdGpuMonitor = {
        popoutStyle = "default";
        minimumWidth = true;
        variants = [
          {
            id = "variant_1791177076814";
            name = "AMD Radeon RX 9070 XT";
            originalName = "AMD Radeon RX 9070 XT";
            description = "Monitor your discrete AMD Radeon RX 9070 XT";
            gpuPci = "0000:09:00.0";
            gpuType = "dGPU";
            icon = "memory";
          }
        ];
      };
    })
    machine.users;
}
