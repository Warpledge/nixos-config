# VPN Lockdown Allowlist (Android)

How to keep Mullvad's split tunnelling working while "Block connections without
VPN" is on. Verified 2026-09-11 on a Galaxy S22 (`SM-S901U`, Android 16 / SDK 36)
with Mullvad as the always-on VPN.

Use `nixm vpn-list` and `nixm vpn-edit` rather than the raw commands below; they
are here so the mechanism is recoverable if the script goes away.

---

## The problem

Android has two separate toggles:

| Setting | Secure key |
| --- | --- |
| Always-on VPN | `always_on_vpn_app` |
| Block connections without VPN | `always_on_vpn_lockdown` |

Always-on alone only restarts the VPN; it does not stop traffic while the tunnel
is down. The leak windows are real: boot before the handshake, reconnects after
roaming, and the VPN app being killed.

Turning lockdown on closes those windows but **kills split tunnelling**. Mullvad
excludes apps with `VpnService.Builder.addDisallowedApplication()`, which drops
them out of the VPN's UID ranges; lockdown's firewall permits only those ranges,
so excluded apps get no network at all rather than a route around the tunnel.

## The fix

`DevicePolicyManager.setAlwaysOnVpnPackage(admin, pkg, lockdown, lockdownAllowlist)`
takes an allowlist of packages exempt from the lockdown firewall. Its persistence
layer is a third secure setting, and **that setting is writable from adb** — no
device owner needed:

```bash
adb shell settings get secure always_on_vpn_lockdown_whitelist
adb shell settings put secure always_on_vpn_lockdown_whitelist "com.a,com.b"
adb reboot
```

Put the same packages in both Mullvad's split tunnel list and this allowlist.

- In Mullvad's list but not this one → blocked outright.
- In this one but not Mullvad's → stays in the tunnel, harmless.

`dpm` has **no** always-on-vpn subcommand; don't go looking for one.

## The reboot is not optional

`Vpn.loadAlwaysOnPackage()` reads these three settings only at boot, and nothing
observes them at runtime. Until you reboot, the setting reads as new while the
firewall still holds the old ranges — it looks applied and is not.

## Verifying it took

`dumpsys connectivity` has a `Lockdown filtering rules:` section listing the
blocked UID ranges. Allowlisted apps appear as **gaps** in otherwise contiguous
ranges:

```bash
adb shell dumpsys connectivity | awk '/Lockdown filtering rules:/{f=1;next} f&&/UIDs:/{print;next} f{exit}'
adb shell 'pm list packages --user 0 -U'        # package -> uid
```

```
... 10339-10341  [gap: 10342 mullvad, 10343 arknights, 10344 weawow]  10345-10350 ...
```

Worth knowing: the exemption is installed even while the VPN is **disconnected**,
so it is a state-independent firewall rule. The AOSP docs describe the allowlist
as applying "when VPN is in lockdown mode but not connected", which is narrower
than what actually happens — it holds while connected and split-tunnelled too.

Mullvad's own UID must also be exempt, and is, automatically.

## Three ways this silently breaks

1. **Toggling either VPN switch in Settings wipes the allowlist.** The GUI calls
   `setAlwaysOnPackage` with an empty list. Split-tunnelled apps go dark until
   the allowlist is re-applied and the phone rebooted.
2. **Adding an app to Mullvad's split tunnel is not enough.** It must go in the
   allowlist too, then reboot — otherwise it is split-tunnelled *and* blocked.
3. **Reinstalling an allowlisted app changes its UID.** The allowlist is stored
   by package name and re-resolved at boot, so it self-heals, but only after a
   reboot. In between, the app can land inside a blocked range.

## Trade-off to keep in mind

Allowlisted apps are outside the tunnel permanently, on the real IP, connected or
not. That is the point for games that ban on VPN IPs and banks that block them,
but it is worth re-reading the list occasionally — privacy-motivated apps drift
onto it by accident.

## Try LAN sharing before split tunnelling

Mullvad's **Local network sharing** toggle covers apps that only need LAN
reachability (self-hosted servers, casting, scrcpy) while keeping them in the
tunnel. Every app it rescues is one that never needs an allowlist entry.
