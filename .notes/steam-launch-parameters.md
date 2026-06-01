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

```
PROTON_USE_NTSYNC=1 PROTON_ENABLE_WAYLAND=1 gamemoderun %command%
```

**Notes:** `PROTON_USE_NTSYNC=1` enables NT sync primitives via the `ntsync` kernel module (loaded in `security/kernel.nix`). Fixes 5-20 min freezes introduced in the 1.2 patch. Requires GE-Proton (set in Steam compatibility settings). Do not enable in-game Reflex — crashes on AMD.

---

## Wuthering Waves

```
STEAMDECK=1 SteamOS=1 PROTON_FSR4_UPGRADE=1 ENABLE_LAYER_MESA_ANTI_LAG=1 MANGOHUD=1 gamemoderun %command% -dx11 -SkipSplash -EngineIni=Engine.ini; pkill -f "WutheringWaves"; pkill -f "CrashReportClient"
```

**Notes:**
- `STEAMDECK=1 SteamOS=1` — Forces Steam Deck/SteamOS identity, needed for Proton compatibility
- `PROTON_FSR4_UPGRADE=1` — Upgrades FSR upscaling to FSR 4; optimized for RDNA 4 (RX 9070 XT)
- `ENABLE_LAYER_MESA_ANTI_LAG=1` — Mesa Anti-Lag Vulkan layer: throttles CPU to stay in sync with GPU when GPU-bound, reducing frame queue depth and input latency. Safe to keep; no-ops when CPU is the bottleneck
- `MANGOHUD=1` — Enables MangoHud FPS overlay
- `; pkill -f "WutheringWaves"; pkill -f "CrashReportClient"` — Runs after game exits/crashes; force-kills any lingering Kuro launcher or crash reporter processes that would otherwise hang Steam indefinitely
- `-dx11` — Forces DirectX 11 rendering; fixes crashes on GE-Proton with this GPU/driver stack (DX12 crashes on launch)
- `-SkipSplash` — Skips intro splash screens
- `-EngineIni=Engine.ini` — Loads custom UE5 engine config overrides from `~/.local/share/Steam/steamapps/common/Wuthering Waves/Client/Saved/Config/WindowsNoEditor/Engine.ini`. **Note:** `r.RayTracing.LoadConfig` must be `1` when RT is enabled in-game, `0` when disabled — mismatch causes crash at 75% load

---

## The Princess, the Stray Cat, and Matters of the Heart 2 (Noratoto 2)

```
LANG=ja_JP.UTF-8 DXVK_FRAME_RATE=120 %command%
```

**Notes:** KiriKiri Z engine (XP3 archives). `LANG=ja_JP.UTF-8` sets Japanese locale for the Wine process — required because KiriKiri Z does Shift-JIS string operations that crash under en-US codepage 1252. The root system issue was `VK_ICD_FILENAMES` pointing only to the 64-bit RADV ICD, causing DXVK to fail with `VK_ERROR_INCOMPATIBLE_DRIVER` in the 32-bit Wine process. Fixed permanently in `hosts/desktop/gpu.nix` to include both 64-bit and 32-bit ICD paths — so the `LANG` override is the only launch option needed now. `DXVK_FRAME_RATE=60` caps FPS via DXVK — KiriKiri Z uses DirectX so DXVK handles it; adjust the value as needed.

---

## Monochrome Mobius

```
LD_PRELOAD="" DXVK_FRAME_RATE=60 DXVK_ASYNC=1 RADV_PERFTEST=gpl mangohud %command%
```

**Notes:** `LD_PRELOAD=""` clears any preloaded libraries that may conflict. `DXVK_FRAME_RATE=60` caps FPS via DXVK. `DXVK_ASYNC=1` enables async shader compilation to reduce stutter. `RADV_PERFTEST=gpl` enables GPL (Graphics Pipeline Library) on RADV for faster pipeline compilation. `mangohud` enables the MangoHud overlay.

---

## Template

Use this format when adding new games:

### Game Name

```
LAUNCH_PARAMETERS_HERE %command%
```

**Notes:** (optional - any relevant info about these parameters)
