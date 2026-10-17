# Undervolt the RX 9070 XT with LACT

**Goal:** lower the 9070 XT's voltage with LACT so it runs cooler and quieter, or holds higher clocks at the same power, without games crashing. The steps assume no overclocking experience.

Added 2026-10-15.

**Status (2026-10-17):** testing phase. The offset is settled at **-70 mV**, applied in LACT and saved to `/etc/lact/config.yaml`; what's left is sustained play to confirm it holds.

The card is an XFX Quicksilver RX 9070 XT Gaming Edition, model `RX-97TQICKB9` (the black version, per the box), rated game clock up to 2400 MHz and boost up to 2970 MHz (XFX spec page): PCI subsystem `1eae:8811`, VBIOS `113-EXT108832-100`, power cap 304 W default and 374 W max.

## What's already in the repo

- `hosts/desktop/hardware/gpu.nix` turns on `services.lact` (the `lactd` daemon plus the LACT app) and amdgpu overdrive with `ppfeaturemask = "0xfff7ffff"`: the kernel's default mask `0xfff7bfff` (`amdgpu_drv.c`) plus the overdrive bit `0x4000` (`amd_shared.h`). Overdrive unlocks clock and voltage settings, a power cap above the default, and fan control on RDNA3 and newer (LACT wiki, "Overclocking (AMD)").
- No LACT settings are declared in Nix, so LACT writes `/etc/lact/config.yaml` itself and its changes persist across reboots.
- With overdrive on, amdgpu logs `Overdrive is enabled, please disable it before reporting any bugs unrelated to overdrive.` at boot (a string in the amdgpu module). It matters only when reporting a GPU bug.
- GameMode's `gpu` section was removed on 2026-10-17 (see "GameMode clock cap" below), so `nix-performance` no longer changes the card's performance level.

## Before you start

- The card stays at stock settings until you apply a change in LACT.
- LACT asks you to confirm each OC change in a dialog before it saves it, so a change that crashes the GPU straight away is dropped (LACT wiki, "Recovering from a bad overclock").
- Too deep an undervolt shows up as a game crash, a GPU driver reset (a black screen for a few seconds, and the desktop session may not survive it), or flicker and artifacts. Back off and test again.
- These steps change only the voltage offset. Raising the power cap or the clocks is overclocking, which means more power and heat, and an undervolt doesn't need it.

## Benchmark results

Unigine Superposition 1.1, Performance mode, 1080p Extreme preset (OpenGL), on 2026-10-17. Only the voltage offset changed between runs: clock offset 0, VRAM clock stock, power cap 304 W. No run crashed, and the kernel log showed no amdgpu reset or timeout after any of them.

| Run | Offset | Score | vs stock | FPS min / avg / max | GPU °C min / max |
| --- | --- | --- | --- | --- | --- |
| 1 | 0 mV (stock) | 14314 | | 83.78 / 107.07 / 130.87 | 51 / 61 |
| 2 | -30 mV | 14457 | +1.0% | 85.96 / 108.14 / 133.44 | 50 / 62 |
| 3 | -70 mV | 14685 | +2.6% | 86.53 / 109.84 / 134.22 | 49 / 61 |
| 4 | -100 mV | 14831 | +3.6% | 87.32 / 110.93 / 134.40 | 54 / 62 |

Temperatures barely move because the benchmark holds the card at its 304 W cap; the lower voltage shows up as higher clocks inside that cap, so the score is the number to compare. Run 4's minimum temperature is higher only because the card was still warm from run 3.

-100 mV passed, but the limit wasn't searched further. -70 was picked for 30 mV of margin below a passing value, since one TechPowerUp owner's card passed Superposition at an offset Heaven crashed on. Owner reports put stable 9070 XT offsets around -50 to -100 mV, with crashes starting near -100 to -150 mV (sources below).

### Sessions at -70 mV

Both on 2026-10-17, with GPU sensors sampled every 2 s from sysfs. Neither left an amdgpu reset or timeout in the kernel log.

- **Arknights Endfield, 12 min:** light load. About 2 min above 40% busy, averaging 112 W (peak 191 W), max junction 59°C.
- **Cyberpunk 2077 2.31, five benchmark runs (19 min, no free play):** about 7 min at full load, averaging 169 W and 2296 MHz, peak 247 W, max junction 65°C and memory 78°C. FreeTube was playing video on the second monitor throughout.

| FSR 4 | Ray tracing | Avg FPS | Min / Max |
| --- | --- | --- | --- |
| Quality | Off | 121.28 | 100.27 / 149.81 |
| Native AA | Off | 69.14 | 59.46 / 90.22 |
| Balanced | On, lighting Medium | 75.51 | 64.32 / 89.14 |
| Quality | On, lighting Medium | 66.79 | 57.14 / 80.43 |
| Quality | Path tracing (the results screen shows RT off) | 36.15 | 31.13 / 41.83 |

All runs at 2560x1440, textures High, borderless window, no frame generation.

Both games ran through `nix-performance`, so GameMode capped them at about 2.4 GHz (next section). The Cyberpunk numbers above are capped results; the full-boost rerun is in the next section.

### GameMode clock cap

The clock never passed about 2.4 GHz in either game above, even at full load and well under the 304 W cap. Two Superposition runs on 2026-10-17 (-70 mV, 1080p Extreme, video playing on the second monitor in both) traced it to GameMode's `amd_performance_level = "high"`:

| Run | Performance level | Avg clock under load | Avg power | Score |
| --- | --- | --- | --- | --- |
| No GameMode | `auto` | 2982 MHz (max 3044) | 304 W | 14590 |
| `gamemoderun` | `high` | 2276 MHz (max 2369) | 159 W | 11679 |

Cyberpunk 2077 again after the rebuild that removed the `gpu` section (2026-10-17, -70 mV, same settings and FreeTube playing): three path tracing runs, then one each of the other three (the reflections-on run came after the recorder stopped). The level stayed `auto` throughout, full-load stretches averaged 2949 MHz and 295 W (max 3172 MHz, junction 83°C, memory 84°C), and the kernel log showed no amdgpu reset or timeout.

| FSR 4 Quality, plus | Capped (GameMode `high`) | Full boost | Change |
| --- | --- | --- | --- |
| Path tracing | 36.15 | 43.50 (min 37.81 / max 50.13) | +20% |
| RT on, lighting Medium, reflections on | 66.79 | 79.05 (min 68.08 / max 95.50) | +18% |
| RT on, lighting Medium, reflections off | | 84.76 (min 75.04 / max 99.78) | |
| RT off | 121.28 | 139.54 (min 111.11 / max 167.92) | +15% |

`pp_dpm_sclk` lists 2400 MHz, the card's rated game clock, as its top level, and "high" pins the card there, so the firmware can't boost toward 2970 MHz. GameMode only began applying it on 2026-10-15, when `gpu_device` was pointed at `card1`; before that it opened `card0` (simpledrm) and skipped the GPU settings. The `gpu` section is now gone from `gamemode.nix`, along with the desktop's `gpu_device` override.

To rerun the benchmark (unfree, so `run` can't start it; its bundled Qt doesn't parse the session's `wayland;xcb` fallback list):

```bash
QT_QPA_PLATFORM=xcb NIXPKGS_ALLOW_UNFREE=1 nix run --impure nixpkgs#unigine-superposition
```

Superposition keeps its data in `~/.Superposition`. A run is written to `results/` only when **Save** is clicked, and the `.score` file is encrypted, so the score in its file name is the only readable part; FPS and temperatures come from the results screen.

## Steps done

Steps 1 to 6 of the original plan, finished 2026-10-17: overdrive confirmed (`ppfeaturemask` reads `0xfff7ffff`), stock baseline recorded, then the offset was bisected (-30, -70, -100) instead of stepped 10 mV at a time, and set to -70 mV.

## Steps left (testing phase)

1. Play an hour or two of a demanding game, menus and loading screens included, since an undervolt often fails on sudden load changes or at light load rather than steady full load. The Cyberpunk benchmarks passed at full boost on 2026-10-17 (see above), including path tracing, but they're about a minute each; free play is still untested. Modded Minecraft with shaders and Distant Horizons gives a long OpenGL load; Cyberpunk free play with RT on covers the ray-tracing hardware.
2. After any crash, check the kernel log for an amdgpu reset or timeout before blaming the undervolt: a clean log plus a game crash report points at the game (mods, Java, shader packs). If it was the undervolt, raise the offset to -60 mV and test again.
3. Use the PC normally for a week (games, video, desktop) at -70 mV.
4. Optional: copy the final settings from `/etc/lact/config.yaml` into `services.lact.settings` so a reinstall keeps them. The file then becomes a read-only link that LACT can't change (the option's description), so do this last.
5. Delete this file once the offset has held through a week of normal play.

## If the desktop crashes before you can reset it

Switch to a text console with Ctrl+Alt+F2 and log in, move the config aside with `sudo mv /etc/lact/config.yaml /etc/lact/config.yaml.bad`, and reboot; the card comes back at stock. LACT's own `lact-reset` boot parameter (LACT wiki, "Recovering from a bad overclock") needs the kernel command line edited at the boot menu, and `security/hardening/default.nix` turns systemd-boot's editor off, so the console route is the one that works here.

## Sources

- LACT wiki, Overclocking (AMD): https://github.com/ilya-zlobintsev/LACT/wiki/Overclocking-(AMD)
- LACT wiki, Recovering from a bad overclock: https://github.com/ilya-zlobintsev/LACT/wiki/Recovering-from-a-bad-overclock
- LACT wiki, Hardware Support (RDNA4 needs kernel 6.14 or newer; this host ran 7.2.8 on 2026-10-15): https://github.com/ilya-zlobintsev/LACT/wiki/Hardware-Support
- amdgpu feature mask bits: https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/amd/include/amd_shared.h
- amdgpu default mask: https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/amd/amdgpu/amdgpu_drv.c
- Unigine Superposition: https://benchmark.unigine.com/superposition
- TechPowerUp forum, 9070 XT owner settling on -90 mV after Heaven crashed below -100: https://www.techpowerup.com/forums/goto/post?id=5472811
- Igor's Lab, RX 9070 undervolting (first crashes at -150 mV): https://www.igorslab.de/en/?p=276010
