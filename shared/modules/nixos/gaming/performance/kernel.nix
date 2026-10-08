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
}
