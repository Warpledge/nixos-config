# When Things Go Wrong

The running system is never touched by a rebuild that fails, so a failure is safe to stop at and read.

## A Rebuild Failed

The run page shows **What Went Wrong**, with a button to copy the error and the full log below it. **Undo My Changes** puts the settings files back as they were. The Maintenance page keeps the last failed run's log under **Last Failed Run** until you choose **Forget It**.

Common causes:

- **A download failed**: the network dropped or a server was slow. Try again with **Rebuild Now**.
- **A package failed to build after an update**: nixpkgs sometimes breaks an app for a while. Undo, then update again with that source unticked, or wait a few days. An admin can switch the app off until it's fixed; [`disabled-packages.md`](../nixpkgs/disabled-packages.md) lists the ones switched off so far.
- **Out of disk space**: run **Clean Up Old Versions** first.

## "Couldn't Read the Settings"

Omni Settings opens on this page when the settings files have a mistake, often a setting the config no longer has. If it lists old settings, **Remove Them** takes them out. Otherwise the message names the file and the setting.

## Something Broke After an Update

Go back a version: Maintenance → **Versions** → **Switch** on the one before. If the desktop won't start at all, restart and pick an older version in the boot menu. Either way your settings files stay as they are, so tell an admin which update broke it.

## The Desktop Froze or Looks Wrong

- The bar or a panel is stuck: `Mod+R` restarts the shell.
- Keys stopped working inside a game or remote desktop: `Mod+Escape` takes them back.
- The whole desktop froze after a rebuild: restart. Updates that are known to do this already wait for a restart, but the restart fixes it either way.
- An app ignores a new colour theme: close and reopen it.

## A Service Isn't Working

Main → **Services** → **Running Now** shows each service's state and its last log lines, with a restart button. In a terminal, `journalctl -b -p err` lists this boot's errors.

## A Game Won't Start

The **Launch Options** and **Proton Versions** pages on the Gaming tab list the launch options that fix common problems and the Proton builds installed. A game that worked before an update often works again on an older Proton version.
