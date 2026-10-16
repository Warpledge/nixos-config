# Undervolt the RX 9070 XT with LACT

**Goal:** lower the 9070 XT's voltage with LACT so it runs cooler and quieter, or holds higher clocks at the same power, without games crashing. The steps assume no overclocking experience.

Added 2026-10-15.

## What's already in the repo

- `hosts/desktop/hardware/gpu.nix` turns on `services.lact` (the `lactd` daemon plus the LACT app) and amdgpu overdrive with `ppfeaturemask = "0xfff7ffff"`: the kernel's default mask `0xfff7bfff` (`amdgpu_drv.c`) plus the overdrive bit `0x4000` (`amd_shared.h`). Overdrive unlocks clock and voltage settings, a power cap above the default, and fan control on RDNA3 and newer (LACT wiki, "Overclocking (AMD)").
- No LACT settings are declared in Nix, so LACT writes `/etc/lact/config.yaml` itself and its changes persist across reboots.
- With overdrive on, amdgpu logs `Overdrive is enabled, please disable it before reporting any bugs unrelated to overdrive.` at boot (a string in the amdgpu module). It matters only when reporting a GPU bug.
- GameMode sets the card's performance level to `high` while a game started through `nix-performance` runs (`modules/nixos/gaming/performance/gamemode.nix`), so test with games launched that way.

## Before you start

- The card stays at stock settings until you apply a change in LACT.
- LACT asks you to confirm each OC change in a dialog before it saves it, so a change that crashes the GPU straight away is dropped (LACT wiki, "Recovering from a bad overclock").
- Too deep an undervolt shows up as a game crash, a GPU driver reset (a black screen for a few seconds, and the desktop session may not survive it), or flicker and artifacts. Back off and test again.
- These steps change only the voltage offset. Raising the power cap or the clocks is overclocking, which means more power and heat, and an undervolt doesn't need it.

## Steps left

1. Run `nixm boot` (the new kernel parameter needs a reboot) and reboot. `cat /sys/module/amdgpu/parameters/ppfeaturemask` should print `0xfff7ffff`.
2. Open LACT and write down the stock values on its OC page: the voltage offset (0 mV), the power cap and the clock limits.
3. Pick a demanding game you play, or one with a built-in benchmark, and note its frame rate plus the GPU clock, power draw and temperature from LACT's charts at stock.
4. Set the voltage offset to -30 mV, apply, and confirm the dialog. Play or benchmark for 20 minutes.
5. If nothing went wrong, go 10 mV deeper and repeat, giving each step 20 minutes.
6. At the first crash, driver reset or artifact, go back to the last offset that held, then 10 mV shallower for margin: if -80 crashed and -70 held, settle on -60.
7. Play other games on the settled value, including any with ray tracing. If one crashes at an offset the others take, raise the offset by 10 mV.
8. Compare with step 3. The same frame rate at lower power and temperature, or higher clocks and frame rate at the same power, means it worked.
9. Optional: copy the final settings from `/etc/lact/config.yaml` into `services.lact.settings` so a reinstall keeps them. The file then becomes a read-only link that LACT can't change (the option's description), so do this last.
10. Delete this file once the offset has held through a week of normal play.

## If the desktop crashes before you can reset it

Switch to a text console with Ctrl+Alt+F2 and log in, move the config aside with `sudo mv /etc/lact/config.yaml /etc/lact/config.yaml.bad`, and reboot; the card comes back at stock. LACT's own `lact-reset` boot parameter (LACT wiki, "Recovering from a bad overclock") needs the kernel command line edited at the boot menu, and `security/hardening/default.nix` turns systemd-boot's editor off, so the console route is the one that works here.

## Sources

- LACT wiki, Overclocking (AMD): https://github.com/ilya-zlobintsev/LACT/wiki/Overclocking-(AMD)
- LACT wiki, Recovering from a bad overclock: https://github.com/ilya-zlobintsev/LACT/wiki/Recovering-from-a-bad-overclock
- LACT wiki, Hardware Support (RDNA4 needs kernel 6.14 or newer; this host ran 7.2.8 on 2026-10-15): https://github.com/ilya-zlobintsev/LACT/wiki/Hardware-Support
- amdgpu feature mask bits: https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/amd/include/amd_shared.h
- amdgpu default mask: https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/amd/amdgpu/amdgpu_drv.c
