# Steam Game Launch Parameters

Documentation of game-specific launch parameters for optimal performance and compatibility.

## Morimens (忘卻前夜 Morimens)

```
PROTON_ENABLE_WAYLAND=0 WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--no-sandbox" %command%
```

**Notes:** `PROTON_ENABLE_WAYLAND=0` forces XWayland — required because Wine's native Wayland driver splits the WebView2 login child window into a separate Wayland surface that can't composite back into the Unity game window (shows as white box). XWayland handles child window compositing correctly. `--no-sandbox` keeps the Chromium renderer process stable under Wine. Also requires a niri window rule for `msedgewebview2.exe` with `clip-to-geometry = false` and `draw-border-with-background = true` (in `shared/modules/wm/niri/niri-home/core/rules.nix`).

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

**Pre-launch script:** declaratively managed in nixos-config
- `shared/modules/home-manager/scripts/gaming/tml-prelaunch.nix`
- Uses `${pkgs.jq}/bin/jq` (nix store path, no PATH dependency)
- Merges settings into existing JSON, preserving all other tModLoader properties
- Idempotent — no-ops if file is missing

### tModLoader.runtimeconfig.json Configuration

**File location:** `/home/warpledge/.local/share/Steam/steamapps/common/tModLoader/tModLoader.runtimeconfig.json`

**Recommended configuration (applied automatically by pre-launch script):**
```json
{
	"runtimeOptions": {
		"tfm": "net8.0",
		"framework": {
			"name": "Microsoft.NETCore.App",
			"version": "8.0.0"
		},
		"configProperties": {
			"DEFAULT_STACK_SIZE": "51200000",
			"System.Reflection.Metadata.MetadataUpdater.IsSupported": false,
			"System.Runtime.Serialization.EnableUnsafeBinaryFormatterSerialization": false,
			"System.GC.Server": true,
			"System.GC.Concurrent": true,
			"System.GC.HeapCount": 8,
			"System.GC.HeapAffinitizeMask": 255
		}
	}
}
```

**Property explanations:**
- `DEFAULT_STACK_SIZE: 51200000` - 512MB per thread (prevents stack overflow with heavy modpacks)
- `System.GC.Server: true` - Server garbage collection (multi-core optimized)
- `System.GC.Concurrent: true` - Concurrent GC reduces stutter
- `System.GC.HeapCount: 8` - One GC heap per core (8 cores on 5800X3D)
- `System.GC.HeapAffinitizeMask: 255` - Pins heaps to cores 0-7 (binary 255 = 0xFF)

**Notes:**
- File is writable by default (tModLoader may regenerate it on update — pre-launch script handles this)
- For Infernal Eclipse of Ragnarok modpack (Calamity + Infernum)

---

## No Rest for the Wicked

```
PROTON_FSR4_RDNA3_UPGRADE=1 PROTON_FSR4_INDICATOR=1 PROTON_ENABLE_WAYLAND=1 gamemoderun %command%
```

**Notes:** Requires GE-Proton (tested with GE-Proton10-30). `PROTON_FSR4_RDNA3_UPGRADE=1` enables FSR4 code path on RX 9070 XT (RDNA4). Remove `PROTON_FSR4_INDICATOR=1` after confirming FSR4 is active via overlay.

---

## Arknights Endfield

**Launched via Heroic (Epic Games Store) using umu-run/Proton, not native Steam.** Environment variables are set per-game in Heroic → Game Settings → Advanced → Environment Variables (not a `%command%` launch string).

```
PROTON_USE_NTSYNC=1
STEAMOS=1
STEAMDECK=1
WEBKIT_DISABLE_COMPOSITING_MODE=1
PROTON_ENABLE_WAYLAND=0
WINEDLLOVERRIDES=winewayland.drv=
```

**Notes:** `PROTON_USE_NTSYNC=1` enables NT sync primitives via the `ntsync` kernel module (loaded in `security/kernel.nix`). Fixes 5-20 min freezes introduced in the 1.2 patch. `STEAMOS=1`/`STEAMDECK=1` force Steam Deck identity, needed for some Proton compatibility paths. `WEBKIT_DISABLE_COMPOSITING_MODE=1` avoids rendering issues in the CEF/WebView login screen. `PROTON_ENABLE_WAYLAND=0` + `WINEDLLOVERRIDES=winewayland.drv=` force XWayland instead of Wine's native Wayland driver — fixes a fatal crash (`xdg_wm_base#N: error 4: wrong configure serial`, `waylanddrv:wayland_read_events_thread Failed to read events from the compositor, terminating process`) where Niri kills the wine process outright when the native Wayland driver acks a stale configure serial while the main game window is setting up its D3D resources. The Heroic per-game "Enable Wine Wayland" checkbox did not reliably force this off, hence the explicit env vars. Requires GE-Proton or equivalent (set in compatibility tool settings). Do not enable in-game Reflex — crashes on AMD.

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
- `-dx12` — Forces DirectX 12 rendering; needed for raytracing. Previously `-dx11` was required because DX12 crashed on launch with GE-Proton on this GPU/driver stack — if that regresses, fall back to `-dx11` and drop `VKD3D_CONFIG=dxr11`
- **Do not add `-EngineIni=Engine.ini`.** Older AlteriaX configs needed it, current ones do not, and leaving it in stops the config from applying properly

**Previously used, currently dropped:**
- `; pkill -f "WutheringWaves"; pkill -f "CrashReportClient"` — ran after exit/crash to force-kill lingering Kuro launcher or crash reporter processes that would otherwise hang Steam indefinitely. Re-add if Steam starts showing the game as still running after quitting

### Graphics config (AlteriaX WuWa-Configs)

Source: https://github.com/AlteriaX/WuWa-Configs

Installed to `~/.local/share/Steam/steamapps/common/Wuthering Waves/Client/Saved/Config/WindowsNoEditor/`:

- `Engine.ini` — **Config 1** (the tier for RX 9070 XT / 7900 XTX / RTX 4080+). Increases foliage draw distance, shadow resolution, AO quality, SSR roughness, volumetric light sampling. Costs some FPS versus default because of the foliage distance increase
- `DeviceProfiles.ini` — unlocks the Ultra quality preset and 120 FPS option on GPUs the game doesn't whitelist (5800X3D is fast enough for 120)
- `Input.ini` — disables mouse smoothing and FoV scaling

**Gotchas:**
- `r.RayTracing.LoadConfig` in `Engine.ini` must be `1` when RT is enabled in-game, `0` when disabled — mismatch causes a crash at 75% load. Config 1 ships with `1`
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
