# Android QUIC VPN Leak — CVE / Mullvad Advisory (May 2026)

## Vulnerability

Any app on Android 16+ can leak traffic outside the VPN tunnel via `registerQuicConnectionClosePayload`, even with **Always-On VPN** and **Block connections without VPN** both enabled. The QUIC graceful shutdown payload is sent without checking it routes through the tunnel, exposing the real IP address.

Source: https://mullvad.net/en/blog/2026/5/12/any-app-on-recent-android-versions-can-leak-certain-traffic

## Mitigation

Requires USB debugging enabled on the phone.

```bash
adb shell device_config put tethering close_quic_connection -1
adb reboot
```

Verify the setting applied before rebooting:

```bash
adb shell device_config get tethering close_quic_connection
# Should output: -1
```

## Important Notes

- Setting persists across reboots but **may be reset by system updates** — reapply after any Android update.
- GrapheneOS has patched this natively; mitigation not needed there.
- If `adb devices` shows `unauthorized`, unlock the phone and accept the USB debugging prompt first.
