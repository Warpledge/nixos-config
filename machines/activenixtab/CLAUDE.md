# activenixtab

Ky's (`kylerj`) ASUS ROG Flow Z13 2025 (GZ302EA-XS99), a 2-in-1 tablet with a
detachable folio keyboard and touchpad. Ryzen AI Max+ 395, Radeon 8060S integrated GPU
(no discrete GPU), 128 GB unified memory, 1 TB SSD, MediaTek MT7925 Wi-Fi. One built-in
touchscreen, `eDP-1`, 2560x1600 at up to 180 Hz, scale 1.5. Running NixOS since
2026-10-25; nobody else logs in.

The checkout lives at `~/nixos-config` (`flakePath`). It pulls Warpledge's main and
pushes to the private backup `votex09/nixos-z13`, which holds that main plus Ky's
commits for this folder and `users/kylerj/` (`INSTALL.md` has the remote setup). Ky's
changes stay in those two folders so a pull never conflicts; a change to a shared file
goes to Warpledge as a pull request through the fork `votex09/nixos-config`, and only
when Ky approves it.

## Hardware

- **GPU:** the 8060S renders everything (`gpu.type = "amd"`). `ttm.pages_limit` and
  `ttm.page_pool_size` in `default.nix` let it borrow up to 120 GiB of RAM as GTT, so
  the UMA carve-out stays low in the BIOS. Local models need that headroom.
- **Kernel:** zen. CachyOS 7.0.x builds hang the ASUS WMI controls on this model.
- **Power and ASUS controls:** `asusd` (asusctl) and power-profiles-daemon. Mod+B cycles
  the power profile.
- **Wi-Fi:** `mt7925e` runs with `disable_aspm=1`; it drops with PCIe power saving on
  some kernels.
- **NPU:** `amdxdna` is loaded; nothing uses it yet.
- **Rotation:** the accelerometer (`hardware.sensor.iio`) drives `iio-niri listen`,
  started from `wm/niri.nix`.
- **Touchscreen:** `wm/touch-gestures.py` turns three-finger drags into touchpad swipes
  so niri scrolls columns and workspaces; fewer fingers pass through.
- **Touchpad:** the folio's toggle key sends F21 (`XF86TouchpadToggle`), bound in
  `home/binds.nix`; it writes `~/.config/niri/touchpad-off`, which `touch-gestures.py`
  watches. Turning the touchpad off in niri would also stop the touchscreen gestures.
  Movement feels smoothed from first contact. hid-multitouch, libinput (flat profile)
  and niri pass the firmware's 270 Hz reports through unchanged (measured 2026-10-25),
  so any filter is in the firmware (it feels the same on Windows). A script that
  moved fingers ahead by their speed was snappier but lost accuracy, so it was
  dropped. Its feature reports hold no filter setting, and HID mouse mode (Input
  Mode 0) is smoothed the same, so the filter sits before both in the folio's ITE
  firmware. Reflashing that has no recovery path without Windows.
- **Scroll speed:** Chromium, Electron and Vivaldi scroll far faster per finger movement
  than GTK, so `wm/niri.nix` gives them `scroll-factor = 0.25`. Qt apps are left as is.
- **Keyboard:** keyd makes a tap of Meta alone open the launcher (Meta+Space).

## Where its config lives

- `settings.nix` — machine toggles and Ky's per-machine app overrides (Claude Code and
  Desktop, opencode, KeePassXC, Audacity)
- `default.nix` — the hardware above, asusd, keyd, input-remapper, Tailscale, Waydroid,
  AppImage binfmt
- `wm/niri.nix` — the monitor, scroll factors, auto-rotation and touchscreen gestures
- `home/apps.nix` — apps with no switch in the user template, and Vivaldi as default
  browser (it isn't one of `lib/default-apps.nix`'s choices)
- `home/binds.nix` — niri binds matching Ky's KDE Plasma shortcuts; repo binds on the
  same keys are switched off by id
- `home/local-ai.nix` — llama-swap on llama.cpp (Vulkan) at `127.0.0.1:8090`, DeepSeek
  V4 Flash and gpt-oss 120B loaded from LM Studio's folder, and opencode's provider for it
- `home/config-reminder.nix` — a zsh notice when the checkout is behind Warpledge's main
- `INSTALL.md` — reinstalling from scratch (run `./setup.sh` and choose “Reinstall activenixtab”; the script will detect the existing machine folder and reapply the exact configuration)
