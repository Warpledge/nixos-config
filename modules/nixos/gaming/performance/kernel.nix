#=====================================================================#
# GAMING KERNEL TUNING
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Kernel Sysctls
  #--------------------------------------------------------------------#
  boot.kernel.sysctl = {
    "vm.unprivileged_userfaultfd" = 1; # Enable userfaultfd for Wine/emulators
  };

  #--------------------------------------------------------------------#
  #-- Kernel Parameters
  #--------------------------------------------------------------------#
  boot.kernelParams = [
    "preempt=full" # Full preemption for better responsiveness
    "threadirqs" # Run IRQ handlers in threads (lower latency)
    "nowatchdog" # Disable watchdog (lower overhead)
  ];

  #--------------------------------------------------------------------#
  #-- CPU Scheduler (sched_ext)
  #--------------------------------------------------------------------#
  #--- scx_lavd: BPF scheduler built for gaming latency on single-CCX CPUs
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = ["--performance"]; # Default autopilot packs light loads onto fewer cores
  };
}
