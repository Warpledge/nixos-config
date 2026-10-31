#=====================================================================#
# UPDATE REMINDER
#=====================================================================#
# A notification once the flake's nixpkgs is maintenance.updateReminderDays
# old (machine settings.nix); imported for admins, who can update
{
  config,
  lib,
  pkgs,
  machine,
  ...
}: let
  days = machine.maintenance.updateReminderDays;

  remind = pkgs.writeShellApplication {
    name = "update-reminder";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.libnotify];
    text = ''
      # dms comes from the system or home profile, not the unit's PATH
      export PATH="$PATH:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin"
      lock="${machine.flakePath}/flake.lock"
      stamp="${config.xdg.stateHome}/omni-settings/update-reminded"

      modified=$(jq -r '.nodes.nixpkgs.locked.lastModified // empty' "$lock" 2>/dev/null || true)
      [[ -n $modified ]] || exit 0
      age=$((($(date +%s) - modified) / 86400))
      ((age >= ${toString days})) || exit 0

      # Once a day at most, however often the timer catches up
      today=$(date +%F)
      [[ $(cat "$stamp" 2>/dev/null) != "$today" ]] || exit 0
      mkdir -p "$(dirname "$stamp")"
      echo "$today" >"$stamp"

      action=$(notify-send -a "Omni Settings" -i system-software-update \
        -A open="Open Omni Settings" "Time to update" \
        "This config's packages are $age days old. Update from Omni Settings' Maintenance tab." ||
        true)
      if [[ $action == open ]]; then
        dms ipc call omniSettings show >/dev/null || true
      fi
    '';
  };
in {
  config = lib.mkIf (days > 0) {
    systemd.user.services.update-reminder = {
      Unit.Description = "Remind to update the NixOS config";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe remind;
      };
    };
    systemd.user.timers.update-reminder = {
      Unit.Description = "Daily check whether the NixOS config is due an update";
      Timer = {
        OnCalendar = "daily";
        OnStartupSec = "5min";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
