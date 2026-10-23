# Launch Parameters

Game-specific launch parameters, and why each one is set.

## Morimens (忘卻前夜 Morimens)

```
PROTON_ENABLE_WAYLAND=0 WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--no-sandbox" %command%
```

**Notes:** `PROTON_ENABLE_WAYLAND=0` forces XWayland, required because Wine's native Wayland driver splits the WebView2 login child window into a separate Wayland surface that can't composite back into the Unity game window (shows as white box). XWayland handles child window compositing correctly. `--no-sandbox` keeps the Chromium renderer process stable under Wine. Also requires a niri window rule for `msedgewebview2.exe` with `clip-to-geometry = false` and `draw-border-with-background = true` (in `modules/wm/niri/home/core/window-rules.json`).

---

## Risk of Rain 2
```
DXVK_ASYNC=1 DXVK_QUEUE_TIMEOUT=10000 DXVK_HUD=compiler %command%
```
**Notes:** fixes shader compilation slowdowns, freezes

---

## tModLoader (Terraria Modloader)

### Steam Launch Parameters (recommended configuration)
```
tml-prelaunch && DOTNET_DefaultStackSize=51200000 gamemoderun %command%
```

**How it works:**
- `tml-prelaunch` — Nix-managed script (in PATH after rebuild) that patches `tModLoader.runtimeconfig.json` before every launch, surviving tModLoader updates
- `&& %command%` — required; chains the patch before the game launches
- `DOTNET_DefaultStackSize=51200000` — redundant env var fallback, kept for safety

**Pre-launch script:** `modules/home/programs/gaming/scripts/tml-prelaunch.nix` merges its settings into `~/.local/share/Steam/steamapps/common/tModLoader/tModLoader.runtimeconfig.json`; its header lists each one and why.

**Notes:** For Infernal Eclipse of Ragnarok modpack (Calamity + Infernum)

---

## No Rest for the Wicked

```
PROTON_FSR4_RDNA3_UPGRADE=1 PROTON_FSR4_INDICATOR=1 PROTON_ENABLE_WAYLAND=1 gamemoderun %command%
```

**Notes:** Requires GE-Proton (tested with GE-Proton10-30). `PROTON_FSR4_RDNA3_UPGRADE=1` enables FSR4 code path on RX 9070 XT (RDNA4). Remove `PROTON_FSR4_INDICATOR=1` after confirming FSR4 is active via overlay.

---

## Arknights Endfield

Steam version (app 4732690), on `dwproton-11.0-14` (as of 2026-10-15).

```
ENABLE_LAYER_MESA_ANTI_LAG=1 nix-performance %command%
```

**Notes:**
- `ENABLE_LAYER_MESA_ANTI_LAG=1`: Mesa Anti-Lag Vulkan layer, the same as for Wuthering Waves
- `nix-performance` clears `LD_PRELOAD`, which drops the Steam overlay. In-game purchases go through the overlay, so launch with plain `%command%` to buy anything
- NTSync is on by default in `dwproton-11.0-14` (its Proton log shows `ntsync: up and running`); it fixed the 5 to 20 minute freezes from the 1.2 patch
- Do not enable in-game Reflex: it crashes on AMD

**Previously used, dropped** (Epic copy in Heroic, before the move to Steam):
- `PROTON_ENABLE_WAYLAND=0 WINEDLLOVERRIDES=winewayland.drv=` forced XWayland, fixing a crash where niri killed Wine (`xdg_wm_base#N: error 4: wrong configure serial`). Re-add if that error comes back
- `STEAMOS=1 STEAMDECK=1` for Steam Deck identity, and `WEBKIT_DISABLE_COMPOSITING_MODE=1` for the login screen

Separately, the game's kernel-mode anti-cheat driver (Tencent "Anti-Cheat Expert", `ace-base.sys`) fails to load under Wine (`unimplemented function ntoskrnl.exe.PsGetProcessExitStatus`). This doesn't appear to be fatal to launching/playing, but the anti-cheat isn't actually running correctly as a result.

---

## Wuthering Waves

```
STEAMDECK=1 SteamOS=1 PROTON_ENABLE_WAYLAND=0 WINEDLLOVERRIDES=winewayland.drv= PROTON_FSR4_UPGRADE=1 ENABLE_LAYER_MESA_ANTI_LAG=1 VKD3D_CONFIG=dxr11 MANGOHUD=1 gamemoderun %command% -SkipSplash -dx12
```

**Notes:**
- `STEAMDECK=1 SteamOS=1` — Forces Steam Deck/SteamOS identity, needed for Proton compatibility
- `PROTON_ENABLE_WAYLAND=0` + `WINEDLLOVERRIDES=winewayland.drv=` — **Required, or you cannot log in.** Forces XWayland instead of Wine's native Wayland driver. See the login section below
- `PROTON_FSR4_UPGRADE=1` — Upgrades FSR upscaling to FSR 4; optimized for RDNA 4 (RX 9070 XT)
- `ENABLE_LAYER_MESA_ANTI_LAG=1` — Mesa Anti-Lag Vulkan layer: throttles CPU to stay in sync with GPU when GPU-bound, reducing frame queue depth and input latency. Safe to keep; no-ops when CPU is the bottleneck
- `VKD3D_CONFIG=dxr11` — Exposes DXR 1.1 raytracing to the game through VKD3D-Proton; required for the in-game RT options to work under Proton
- `MANGOHUD=1` — Enables MangoHud FPS overlay
- `-SkipSplash` — Skips intro splash screens
- `-dx12` — Forces DirectX 12 rendering; needed for raytracing. Previously `-dx11` was required because DX12 crashed on launch with GE-Proton on this GPU/driver stack; if that regresses, fall back to `-dx11` and drop `VKD3D_CONFIG=dxr11`
- **Do not add `-EngineIni=Engine.ini`.** Older AlteriaX configs needed it, current ones do not, and leaving it in stops the config from applying properly

**Previously used, dropped:**
- `; pkill -f "WutheringWaves"; pkill -f "CrashReportClient"` — ran after exit/crash to force-kill lingering Kuro launcher or crash reporter processes that would otherwise hang Steam indefinitely. Re-add if Steam starts showing the game as still running after quitting

### Graphics config (AlteriaX WuWa-Configs)

Source: https://github.com/AlteriaX/WuWa-Configs

Installed to `~/.local/share/Steam/steamapps/common/Wuthering Waves/Client/Saved/Config/WindowsNoEditor/`:

- `Engine.ini` — **Config 1** (the tier for RX 9070 XT / 7900 XTX / RTX 4080+). Increases foliage draw distance, shadow resolution, AO quality, SSR roughness, volumetric light sampling. Costs some FPS versus default because of the foliage distance increase
- `DeviceProfiles.ini` — unlocks the Ultra quality preset and 120 FPS option on GPUs the game doesn't whitelist (5800X3D is fast enough for 120)
- `Input.ini` — disables mouse smoothing and FoV scaling

**Gotchas:**
- `r.RayTracing.LoadConfig` in `Engine.ini` must be `1` when RT is enabled in-game, `0` when disabled; a mismatch causes a crash at 75% load. Config 1 ships with `1`
- `Client/Config/UserEngine.ini` must not exist, it overrides `Engine.ini`. Not present on this install
- Comments inside `Engine.ini` are stripped on first launch, that's normal. Keep the repo clone around to re-read them
- Game patches do not reset these files, so no reinstall needed per update. Re-pull if something breaks
- Missing character shadows or blurry textures after a config change: switch graphics preset away and back, then re-customize
- Depth of Field and Vignette are left enabled by default, uncomment `r.DepthOfFieldQuality=0` and `r.Tonemapper.Quality=1` in `Engine.ini` to kill them

---

## Template

Use this format when adding new games:

### Game Name

```
LAUNCH_PARAMETERS_HERE %command%
```

**Notes:** (optional - any relevant info about these parameters)
