#=====================================================================#
# DISPLAY MANAGER ACTIVATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Mask Cleanup
  #--------------------------------------------------------------------#
  # Switching windowManager (gdm <-> greetd) leaves the old display manager's
  # unit masked, and switch-to-configuration only unmasks units it considers
  # active, so the new one cannot start. Unmask both before each activation.
  system.activationScripts.unmaskDisplayManagers = ''
    ${pkgs.systemd}/bin/systemctl unmask gdm.service greetd.service 2>/dev/null || true
  '';
}
