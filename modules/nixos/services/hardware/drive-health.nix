#=====================================================================#
# DRIVE HEALTH (SMART READINGS FOR OMNI SETTINGS' DRIVES PAGE)
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- SMART Readings
  #--------------------------------------------------------------------#
  environment.systemPackages = [pkgs.smartmontools];

  #--- smartctl needs root, so this leaves a world-readable file with the health
  #--- fields only (no serial numbers). -n standby leaves sleeping disks asleep;
  #--- they keep their last reading.
  systemd.services.drive-health = {
    description = "Read each drive's SMART health";
    path = [pkgs.coreutils pkgs.gawk pkgs.jq pkgs.smartmontools pkgs.util-linux];
    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = "drive-health";
      RuntimeDirectoryMode = "0755";
      RuntimeDirectoryPreserve = true;
      PrivateNetwork = true;
      ProtectHome = true;
    };
    script = ''
      file=/run/drive-health/health.json
      old=$(cat "$file" 2>/dev/null || echo '{}')
      all='{}'
      for dev in $(lsblk -dnpo PATH,TYPE | awk '$2 == "disk" && $1 !~ /zram/ {print $1}'); do
        read=$(smartctl -j -n standby -H -A "$dev" 2>/dev/null || true)
        all=$(jq -c --arg dev "$dev" --argjson old "$old" --argjson read "''${read:-{\}}" '
          def attr($id): ($read.ata_smart_attributes.table // [] | map(select(.id == $id))[0].raw.value);
          . + {($dev): (
            if $read.smart_status == null and $old.drives[$dev] != null then $old.drives[$dev]
            else {
              passed: $read.smart_status.passed,
              temperature: $read.temperature.current,
              hours: $read.power_on_time.hours,
              wear: $read.nvme_smart_health_information_log.percentage_used,
              reallocated: attr(5),
              pending: attr(197)
            } end)}' <<<"$all")
      done
      new=$(mktemp -p /run/drive-health)
      jq -n --argjson drives "$all" --argjson checked "$(date +%s)" \
        '{checked: $checked, drives: $drives}' >"$new"
      chmod 644 "$new"
      mv "$new" "$file"
    '';
  };

  systemd.timers.drive-health = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1h";
    };
  };
}
