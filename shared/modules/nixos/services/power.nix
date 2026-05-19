#=====================================================================#
# POWER MANAGEMENT CONFIGURATION
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Power Management
  #--------------------------------------------------------------------#
  powerManagement = {
    enable = true; # Enable power management services
    powerDownCommands = ''
      loginctl lock-sessions
      sleep 1
    '';
  };

  #--------------------------------------------------------------------#
  #-- Sleep Configuration
  #--------------------------------------------------------------------#
  systemd.sleep.settings.Sleep = {
    AllowSuspend = true;
    AllowHibernation = false;
    AllowSuspendThenHibernate = false;
    AllowHybridSleep = false;
  };
}
