#=====================================================================#
# AUDITD CONFIGURATION
#=====================================================================#
#--- Original Code by NotAShelf - https://github.com/notashelf/nyx
{
  #--------------------------------------------------------------------#
  #-- Audit Daemon Configuration
  #--------------------------------------------------------------------#
  security = {
    auditd.enable = true; # Enable system auditing daemon
    audit = {
      enable = false; # Disable audit subsystem due to rule syntax issues
      backlogLimit = 8192; # Maximum audit event backlog
      failureMode = "printk"; # Print failures to kernel log
      rules = [
        "-a exit,always -F arch=b64 -S execve" # Log all process executions (64-bit)
      ];
    };
  };

  #--------------------------------------------------------------------#
  #-- Systemd Timer and Service for Audit Log Cleanup
  #--------------------------------------------------------------------#
  systemd = {
    timers."clean-audit-log" = {
      description = "Periodically clean audit log";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily"; # Run daily cleanup
        Persistent = true; # Persist state across reboots
      };
    };

    services."clean-audit-log" = {
      script = ''
        set -eu
        if [[ $(stat -c "%s" /var/log/audit/audit.log) -gt 524288000 ]]; then
          echo "Clearing Audit Log";
          rm -rvf /var/log/audit/audit.log; # Delete if exceeds 500MB
          echo "Done!"
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
