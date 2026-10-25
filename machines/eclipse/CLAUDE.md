# eclipse

warpledge's desktop: Ryzen 7 5800X3D, RX 9070 XT, a 280Hz OLED and a 144Hz monitor.

## Hardware

AMD-only (RX 9070 XT direct rendering), performance governor. Suspend is disabled because
the RX 9070 XT doesn't resume cleanly. LACT runs with amdgpu overdrive on (`ppfeaturemask`
is the kernel default plus the overdrive bit), set in `hardware/gpu.nix`. GameMode has no
`gpu` section: its `amd_performance_level = "high"` pinned the card to the 2400 MHz game
clock (about 20% slower in Superposition), so don't add it back.

## Where its config lives

- `default.nix` — the governor, suspend off, DDC/CI brightness (`i2c`), and the
  desktop-only home-manager modules in `games/` (xsystem4, Tobira)
- `hardware/gpu.nix` — LACT, overdrive and the DMS GPU widget
- `hardware/storage.nix` — unlocks the LUKS game drives after boot from key files on the
  encrypted root (crypttab)
- `wm/niri.nix` — monitors and the DMS bars
