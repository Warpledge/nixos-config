---
name: android-debloat-redo
description: Redo or change the de-Googled debloat of the Lenovo Idea Tab Pro (TB373FU) over adb, using the procedure and removal list in this repo's .notes. Use after a ZUI/Android system update on the tablet (an OTA restores every stock package), when the user wants to remove or restore a package on the tablet, or when the tablet bootloops or misbehaves after a removal.
---

# Tablet debloat redo

The procedure, its reasons and the exact commands live in
`.notes/android/debloat/Lenovo-Idea-Tab-Pro/index.md`, with the package list in
`removal-list.txt` next to it. Read the note before touching the device; this skill adds
the order and the checks that keep a mistake from costing a factory reset.

## Before anything runs on the device

```bash
bash <skill-dir>/scripts/check-list.sh
```

It reads the note's "Never remove these" table and suffix rule (`.resources`,
`.resources.overlay`, `controller`) and refuses the list if it names any of them. Run it
after every edit to `removal-list.txt`. Removing `com.google.android.sdksandbox` is
unrecoverable (bootloop inside PackageManager), so a package that isn't already on the
verified list goes to the user for a decision first, never straight into a run.

## Order

Follow the note's steps; the ones that bite when skipped:

1. **Replacements first** (Step 1): installed before the debloat, because an OTA also
   deletes sideloaded apps.
2. **Loop on the device, not the host** (Step 2): `adb shell` eats stdin, so a host-side
   `while read` loop stops after one package and still looks successful.
3. **Flush before rebooting**: `adb shell 'sleep 25; sync'`. PackageManager writes
   `package-restrictions.xml` about 10 s late; reboot sooner and every package returns.
4. **Reboot test** (Step 3): a cold boot runs checks a warm one doesn't. Expect the
   package count the note gives (188 as of the note's last update); a higher count means
   packages came back.
5. Then privacy settings, Mullvad always-on, extra F-Droid repos and Dhizuku (Steps 4-7).

## When it goes wrong

- Restore one package: `adb shell cmd package install-existing --user 0 <pkg>`.
- **Bootloop**: adbd still runs; race the package service with the loop in the note's
  Recovery section. If Android offers a factory reset (RescueParty), the answer is
  **"Try again"**, never the wipe.
- Before calling the tablet broken, rule out the four adb traps in the note (black
  screencap while asleep, `resolve-activity` without `-a`, `am start` while locked,
  Mullvad's activity-alias).

If the note's package counts or steps change during the redo, update the note too.
