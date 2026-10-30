#=====================================================================#
# BATTERY CHARGE LIMIT (battery.chargeLimit IN THE MACHINE'S SETTINGS.NIX)
#=====================================================================#
{machine, ...}: {
  #--------------------------------------------------------------------#
  #-- Charge Limit
  #--------------------------------------------------------------------#
  #--- Checked at runtime, since the same setting covers any laptop: Lenovo's
  #--- conservation mode where ideapad_acpi has it, else the kernel threshold
  systemd.services.battery-charge-limit = {
    description = "Battery charge limit";
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      shopt -s nullglob
      set=0
      for f in /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode; do
        echo 1 > "$f" && set=1
      done
      if [ "$set" = 0 ]; then
        for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
          echo ${toString machine.battery.chargeLimit} > "$f" && set=1
        done
      fi
      [ "$set" = 1 ] || echo "No charge limit control found on this machine"
    '';
  };
}
