# Lenovo Idea Tab Pro (TB373FU) Debloat

De-Googled, wifi-only setup. Android 16 / ZUI. Stock image is 315 packages. Removing the 131 leaves 184 stock packages, so expect **188** if you followed Step 1 and installed the 4 replacement apps first.

Files here:

- `index.md` (this file), the full procedure
- `removal-list.txt`, the 131 packages to remove, verified safe on this device

**Redo this after every system update.** A ZUI OTA restores all 315 stock packages and deletes sideloaded apps.

---

## Never remove these

Getting this wrong costs you a factory reset, so check the list before adding anything new.

| Package | If removed |
| --- | --- |
| `com.google.android.sdksandbox` | **Unrecoverable.** Bootloops inside the PackageManager constructor, so `cmd package` never comes up and you cannot repair it. Factory reset only. |
| `com.android.location.fused` | Bootloops at boot phase 600. Recoverable, see Recovery below. |
| `com.google.android.uwb.resources` | Crashes RangingService. Recoverable. |
| `com.android.devicelockcontroller` | Crashes DeviceLockService. Recoverable. |
| `com.google.android.packageinstaller` | Required by PackageManager at construction. |
| `com.google.android.permissioncontroller` | Required by PackageManager at construction. |
| `com.zui.launcher`, `com.zui.desktoplauncher`, `com.zui.homesettings` | No home screen, falls back to a blank `FallbackHome`. **`com.zui.launcher` must stay even if you use a third-party launcher**, see below. |

General rule: never remove anything ending in `.resources`, `.resources.overlay`, or `controller`.

---

## Step 1: install replacements first

Do this **before** debloating. Gboard and the Google TTS voice IME are the only two keyboards on a stock image and both get removed, so without a replacement installed and selected you end up with no way to type.

Working download URLs (the obvious F-Droid one is a 404 that silently saves an HTML error page):

```bash
# F-Droid Basic and Aurora Store: get suggestedVersionCode from the API first
curl -s https://f-droid.org/api/v1/packages/org.fdroid.basic
curl -s https://f-droid.org/api/v1/packages/com.aurora.store
# then
curl -L -o fdroid.apk https://f-droid.org/repo/org.fdroid.basic_<code>.apk
curl -L -o aurora.apk https://f-droid.org/repo/com.aurora.store_<code>.apk

# FUTO Keyboard is not on F-Droid. Parse their repo index for the apk name + sha256
curl -s https://app.futo.org/fdroid/repo/index.xml | grep -A5 org.futo.inputmethod.latin
curl -L -o futo.apk https://app.futo.org/fdroid/repo/keyboard-<code>.apk   # ~134 MiB

# Mullvad works directly
curl -L -o mullvad.apk https://mullvad.net/download/app/apk/latest
```

Install and select the keyboard:

```bash
for f in futo.apk fdroid.apk aurora.apk mullvad.apk; do adb install -r "$f"; done

adb shell ime enable org.futo.inputmethod.latin/.LatinIME
adb shell ime set    org.futo.inputmethod.latin/.LatinIME
adb shell settings get secure default_input_method   # confirm before continuing
```

---

## Step 2: run the debloat

Push the list and loop **on the device**. Do not loop on the host: `adb shell` eats stdin, so a `while read` loop on your PC silently stops after the first package while still looking like it worked.

```bash
adb push removal-list.txt /data/local/tmp/
adb shell 'while IFS= read -r p; do [ -z "$p" ] && continue; \
  echo "$(pm uninstall --user 0 "$p" 2>&1)|$p"; done < /data/local/tmp/removal-list.txt'
```

Expect 131 `Success` lines. A few may report failure on a fresh image, that is fine: `com.king.candycrushsaga`, `com.pinterest` and `com.vitastudio.mahjong` are downloaded bloat and only exist after the tablet has been online for a while.

**Then flush before rebooting:**

```bash
adb shell 'sleep 25; sync'
```

PackageManager delays writing `package-restrictions.xml` by about 10 seconds. Rebooting too early means every package quietly comes back on boot, while the uninstalls all reported `Success` and the reboot test appears to pass.

---

## Step 3: reboot test and verify

Booting successfully proves nothing on its own. The PackageManager checks that kill the device only run on a cold boot, and packages can silently return.

```bash
adb reboot && adb wait-for-device
adb shell 'for i in $(seq 1 90); do [ "$(getprop sys.boot_completed)" = "1" ] && { echo BOOTED; exit 0; }; sleep 2; done; echo TIMEOUT'

# 188 = 184 stock + the 4 apps from Step 1. Nothing from the removal list should come back.
adb shell 'pm list packages --user 0' | wc -l
```

---

## Step 4: privacy settings

```bash
# captive portal off Google
adb shell settings put global captive_portal_http_url  "http://connectivitycheck.grapheneos.network/generate_204"
adb shell settings put global captive_portal_https_url "https://connectivitycheck.grapheneos.network/generate_204"
adb shell settings put global captive_portal_fallback_url "https://connectivitycheck.grapheneos.network/generate_204"
adb shell settings put global captive_portal_use_https 1

adb shell settings put global assisted_gps_enabled 0      # SUPL talks to supl.google.com
adb shell settings put global package_verifier_enable 0
adb shell settings put global ntp_server time.cloudflare.com
adb shell settings put global wifi_scan_always_enabled 0
adb shell settings put global ble_scan_always_enabled 0
adb shell settings put global wifi_networks_available_notification_on 0
adb shell settings put global stay_on_while_plugged_in 0
adb shell settings put secure send_action_app_error 0
adb shell settings put system show_password 0            # note: system, not secure

# leave Private DNS OFF, see below
adb shell settings put global private_dns_mode off
```

Already 0 out of the box, worth confirming: `location_mode`, `lock_screen_show_notifications`.

**Do not set Private DNS.** Strict mode DoT alongside Mullvad's lockdown tunnel can break resolution or push DNS outside the tunnel. Use Mullvad's own in-app DNS content blocking instead.

---

## Step 5: Mullvad always-on VPN

Log in and connect in the app first, then:

```bash
adb shell settings put secure always_on_vpn_app net.mullvad.mullvadvpn
adb shell settings put secure always_on_vpn_lockdown 1
adb shell 'ip -o link show | grep tun'   # verify the tunnel is up
```

Lockdown blocks everything outside the tunnel, which can include adb over wifi on your LAN. USB is unaffected.

---

## Step 6: extra F-Droid repos

Each of these opens a confirm dialog on the tablet that you have to tap. The repo list is stored in F-Droid's own database, which is not readable over adb, so this cannot be verified from the PC. Check **Settings > Repositories** in F-Droid afterwards.

```bash
adb shell input keyevent KEYCODE_WAKEUP

# IzzyOnDroid
adb shell "am start -a android.intent.action.VIEW -d 'fdroidrepos://apt.izzysoft.de/fdroid/repo?fingerprint=3BF0D6ABFEAE2F401707B6D966BE743BF0EEE49C2561B9BA39073711F628937A'"

# FUTO (source of FUTO Keyboard)
adb shell "am start -a android.intent.action.VIEW -d 'fdroidrepos://app.futo.org/fdroid/repo?fingerprint=39D47869D29CBFCE4691D9F7E6946A7B6D7E6FF4883497E6E675744ECDFA6D6D'"

# IronFox (hardened Firefox, fills the no-browser gap)
adb shell "am start -a android.intent.action.VIEW -d 'fdroidrepos://fdroid.ironfoxoss.org/fdroid/repo?fingerprint=C5E291B5A571F9C8CD9A9799C2C94E02EC9703948893F2CA756D67B94204F904'"
```

If a fingerprint ever changes, derive it from the repo itself rather than trusting a copy-paste. It is the SHA-256 of the signing certificate in DER form, which is exactly what F-Droid pins:

```bash
curl -sfL -o index-v1.jar https://<repo>/index-v1.jar
sig=$(unzip -l index-v1.jar | grep -oiE 'META-INF/[A-Z0-9_-]+\.(RSA|EC|DSA)' | head -1)
unzip -p index-v1.jar "$sig" > sig.der
nix shell nixpkgs#openssl -c sh -c '
  openssl pkcs7 -inform DER -in sig.der -print_certs -out certs.pem
  openssl x509 -in certs.pem -noout -subject
  openssl x509 -in certs.pem -outform DER | sha256sum | cut -d" " -f1 | tr "a-z" "A-Z"'
```

`openssl` is not in the system profile, hence the `nix shell`. If you forget that and redirect stderr away, the command silently prints `E3B0C442...`, which is the SHA-256 of an empty string, not a real fingerprint.

---

## Step 7: Dhizuku as device owner

Lets apps use ADB-level privileges on-device without a PC attached. Install Dhizuku first (IzzyOnDroid, or GitHub releases for `com.rosan.dhizuku`).

Check all three preconditions, the command fails if any is wrong:

```bash
adb shell 'dumpsys account | grep -cE "Account \{"'   # must be 0
adb shell pm list users                                # must be a single user
adb shell dpm list-owners                              # must be "no owners"

adb shell dpm set-device-owner com.rosan.dhizuku/.server.DhizukuDAReceiver
adb shell dpm list-owners                              # verify
```

This works even with `com.android.managedprovisioning` debloated: DevicePolicyManagerService inside `system_server` serves the command, the provisioning APK is not needed. Confirmed on two separate passes.

Android allows exactly one device owner, and it can only be set while there are zero accounts, so this blocks adding a Google account later. Open the Dhizuku app once afterwards so it initialises.

Undo:

```bash
adb shell dpm remove-active-admin com.rosan.dhizuku/.server.DhizukuDAReceiver
```

---

## Optional: Smart Connect

Not in the main list, remove separately if you want it gone. "Smart Connect" is Motorola **Ready For** rebranded, so nothing is actually named smartconnect:

```bash
adb shell pm uninstall --user 0 com.motorola.mobiledesktop
adb shell pm uninstall --user 0 com.motorola.mobiledesktop.core
adb shell 'sleep 25; sync'
```

It runs two always-on foreground services holding Bluetooth scan/advertise plus wifi control. Removing it costs desktop mode on an external monitor and phone/PC pairing. Screen mirroring to the NixOS box is better handled by `scrcpy` anyway (`hostConfig.scrcpy.enable`), which needs nothing installed on the tablet.

---

## Recovery

Restore one package:

```bash
adb shell cmd package install-existing --user 0 <pkg>
```

If that returns `NameNotFoundException` and a reboot does not bring it back, the system APK is usually still on disk:

```bash
adb shell 'find /system /product /system_ext -iname "*<name>*"'
adb shell pm install -r /system/priv-app/<Name>/<Name>.apk
```

That works but the app lands in `/data/app` as an ordinary package and loses its privileged permissions.

**If the tablet bootloops**, adbd still runs. Race the package service, it only lives a few seconds per crash cycle:

```bash
adb logcat -d -b crash | tail -40    # confirm which package is at fault
adb shell 'for i in $(seq 1 100); do out=$(cmd package install-existing --user 0 com.android.location.fused 2>&1); \
  case "$out" in *installed*) echo "$out"; exit 0;; esac; sleep 1; done'
```

Repeated crashes make Android offer a factory reset via RescueParty. Pick **"Try again"**, never the wipe.

---

## adb traps that fake a broken device

All four of these looked like real breakage and were not:

- **`adb exec-out screencap -p` returns a pure black PNG when the screen is asleep.** Run `adb shell input keyevent KEYCODE_WAKEUP` first. A screenshot is the quickest way to confirm the tablet is actually fine.
- **`cmd package resolve-activity -c android.intent.category.LAUNCHER <pkg>` finds nothing unless you also pass `-a android.intent.action.MAIN`.** Without the action every app looks iconless. To check drawer icons properly use `cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.LAUNCHER`.
- **`am start` on a locked device reports `Activity class does not exist`** for activities that are perfectly healthy. Unlock first.
- **Mullvad ships app-icon obfuscation.** Its launcher entry is an activity-alias, so `monkey -p net.mullvad.mullvadvpn` aborts with "No activities found to run". The app is fine. Shell also cannot `pm enable` another app's components, that throws a SecurityException.

## WebView cannot be replaced without root

Do not bother trying to swap in Mulch, Vanadium or Bromite. `WebViewUpdateService` only accepts providers from a compiled-in allowlist, and on this device that is Google-only:

```
com.google.android.webview          <- installed, current
com.google.android.webview.{beta,dev,canary,debug}
com.android.webview                 <- AOSP, would need the device platform key
```

Check it with `adb shell dumpsys webviewupdate`. Changing the allowlist means modifying the system partition, and the bootloader is locked (`verifiedbootstate=green`).

It matters less than it looks: IronFox ships its own GeckoView engine so browsing never touches WebView, and WebView's SafeBrowsing calls into GMS which is gone. What remains is the periodic variations ("Finch") config fetch, which is independent of GMS. Block that with Mullvad's in-app DNS blocking if you care.

**Keep `com.google.android.webview` installed.** Any app rendering web content crashes without a provider.

---

## Known gaps after this debloat

No camera, browser, clock/alarm, calculator, contacts or calendar. Fill from F-Droid or Aurora. IronFox covers the browser, Fossify Gallery covers image browsing (the debloat leaves only the system photo *picker*, which other apps invoke, not something you can open yourself).

Copying wallpapers over:

```bash
adb push .wallpapers/. /sdcard/Pictures/Wallpapers/
```

MediaStore indexes them automatically via FUSE, no manual scan needed. `com.zui.wallpapersetting` and `com.android.wallpapercropper` survive the debloat, so Settings > Wallpaper still works.
