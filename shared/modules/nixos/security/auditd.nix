#=====================================================================#
# AUDITD CONFIGURATION
#=====================================================================#
#--- Original Code by NotAShelf - https://github.com/notashelf/nyx
{
  #--------------------------------------------------------------------#
  #-- Audit Daemon Configuration
  #--------------------------------------------------------------------#
  security = {
    auditd.enable = true;
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
        OnCalendar = "daily";
        Persistent = true; # Run on next boot if the machine was off at the scheduled time
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
