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
- `home/binds.nix` — niri binds matching Ky's KDE Plasma shortcuts; each wins its key
  (`winsKey`), so a repo bind on the same key, even one added later, is switched off
- `home/local-ai.nix` — Ky's opencode agents and extras around the config's
  llama-swap (`user.llamaSwap.enable`): ask-claude, ask-claude-auto,
  opencode-desktop, `Projects/opencode.json`, and `modalities`/`limit.output`
  overrides for the provider entries (upstream's provider block has neither).
  The models themselves are machine settings: `settings.nix`'s `localModels`
  block adds Qwen3.8 Flash Next UD-IQ3_XXS (opencode's default, one slot of
  256K, `reasoning_effort` medium for the agents and their `-instruct` alias
  alike) and Nemotron 3.5 Super VL (3 slots with MTP drafting, the pick if the
  budget drops to 80 GB) to the config's catalog, both with vision through
  `--mmproj`, loaded from LM Studio's folder on `127.0.0.1:8090`;
  `localModels.profile = "strix-halo"` and `gpuSharedGB = 120` carry the GPU
  tuning and the GTT kernelParams (llama.cpp 0.7.0 from nixpkgs). Models stay
  within 90 GB (Ky, 2026-10-27) so other
  work keeps memory; a Godot test needs 5 GB free to start. Every model tested or tuned here
  gets an entry in `local-ai-models.md`, measured with the scripts in
  `local-ai-bench/`: the at-a-glance table and a plain-language section first (what
  to pick it for, how long Ky waits, RAM left, what to watch out for), then its
  settings to copy and the raw numbers. Show results to Ky the same way. opencode's two primary agents,
  `system` (the default) and `gamedev` (the default in any project under `~/Projects`,
  through `~/Projects/opencode.json`), take their prompts from `home/agents/`; `system`'s also carries
  this file and `users/kylerj/CLAUDE.md`, so a change here needs a rebuild to reach
  it. Both edit files themselves, and use subagents only when it helps or a skill
   calls for one; opencode denies them `git config`/`remote`/`push`/`checkout`/
   `reset`/`clean`/`restore` and garbage collection; opencode compacts their sessions
   near 48K so a cache miss stays cheap. The agents use v2's
  `agents` key: the file is read as v2, which drops a v1 agent's `permission`.
  opencode asks Ky before any agent edits a file in `~/nixos-config` outside
  `machines/activenixtab/` and `users/kylerj/`. When stuck they run
  `ask-claude`, a one-off read-only `claude -p` whose answer they apply themselves.
  Each call waits for Ky's approval in a notification unless `ask-claude-auto on`
  (or the notification's "Allow until turned off") has switched that off; opencode
  denies the agents `ask-claude-auto`
- `home/config-reminder.nix` — a zsh notice when the checkout is behind Warpledge's main
- `home/ghostty.nix` — Ghostty with `ghostty-touch.patch` (a tap clicks at the finger,
  a one-finger drag scrolls), built from source since the patched package isn't
  cached, and the DMS colour theme the shared module doesn't load yet
- `home/on-screen-input/` — for use without the folio: wvkbd, full width and 390 px
  tall, translucent (`--alpha`) over niri's blur (a layer rule blurs its namespace),
  touch-only (no mouse listener). Layout is Ky's (wvkbd-layout.patch): staggered QWERTY,
  no F-key row (top row = numbers), Esc where Caps was, no Cmp, no right Alt/Ctrl/Shift;
  Fn (bottom left, tap on, tap off) flips to the same keyboard with F1-F12 on the numbers,
  Ins, Del, and Home/PgUp/PgDn/End on the arrows; caps locks on a double-tap of shift
  (wvkbd-caps-shift.patch); PAD (a Material Symbols glyph, F13) sits where right Shift
  would on both layers. A user service starts wvkbd hidden, coloured by a
  matugen template, shown and hidden with `osk-toggle`. And pad mode, in
  `wm/touch-gestures.py`: touches outside the bar and the shown keyboard go to a virtual
  touchpad, so libinput's tap, scroll and drag apply. It has no window on purpose: a
  surface under the pointer would swallow the clicks and scrolls the pad produces.
  `osk-pad-mode` (SIGUSR2) toggles it — the PAD key (KEY_F13, which xkb maps to the
  keysym `XF86Tools`, so that's the niri bind; `F13` never fires) or the bar button.
  Each has a DMS bar plugin (`oskToggle`, `touchpadToggle`) added from DMS's bar
  settings; a one-finger swipe up from the bottom edge also runs `osk-toggle`
  (`wm/touch-gestures.py`). Gotchas: wvkbd must be built WITH `wvkbd-uinput.patch` or
  niri binds never see its keys; touch-gestures starts with niri, so a change to it
  needs a new login, not just a rebuild; KEY_F13 is
  evdev code 183, not 191 (191 is F21 — the folio's own toggle key, which is why
  probe scripts mixing those up found "no F13 anywhere"); niri grabs every input
  device exclusively, so an outside watcher can never read wvkbd's uinput events —
  trust wvkbd's own `-o` log instead; `lib.getExe` as a niri bind's only
  `action.spawn` item breaks the kdl render — interpolate `"${pkg}/bin/pkg"`.
  `raise-watch.py` (`osk-raise.service`) re-creates the keyboard's surface when another
  overlay opens, since niri stacks the newest layer surface on top
- `home/godot-mcp.nix` — the godot-mcp server, built from GitHub at a pinned commit and
  put on PATH; a Godot project's `opencode.json` starts it (`~/godot-mcp-demo` does)
- `home/unreal-engine.nix` — `unreal-editor` and its desktop entry: Epic's prebuilt
  5.8.4 editor in `~/Games/UnrealEngine/` (extracted by hand, not in git), run in
  Steam's FHS environment plus nss/nspr
- `INSTALL.md` — reinstalling from scratch (run `./setup.sh` and choose “Reinstall activenixtab”; the script will detect the existing machine folder and reapply the exact configuration)
