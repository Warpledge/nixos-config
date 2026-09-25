# Game Launcher Environment Variables & Wrappers

Common per-game environment variables and wrapper commands for Wine/Proton-GE
games run through **Heroic**, **Lutris**, **Faugus**, **umu**, or **Steam**.

**Where to put these:**
- **Heroic** — game → Settings → *Advanced* → **Environment Variables** table
  (one `KEY` / `VALUE` row each) and the **Wrapper command** field for wrappers.
- **Lutris** — game → Configure → *System options* → **Environment variables**
  and **Command prefix** (wrapper).
- **Faugus** — per-game launch options.
- **Steam** — Properties → **Launch Options**, written inline before `%command%`,
  e.g. `LANG=ja_JP.UTF-8 PROTON_USE_WINED3D=1 gamemoderun %command%`.

---

## Japanese locale (mojibake fix)

Non-Unicode (Shift-JIS) Japanese games/VNs render kana/kanji as garbage
("mojibake") unless the process runs under a Japanese locale.

```
LANG=ja_JP.UTF-8
```
```
LC_ALL=ja_JP.UTF-8
```

**Notes:** Linux equivalent of Locale Emulator / AppLocale on Windows. The
`ja_JP.UTF-8` locale is already enabled system-wide in
`shared/modules/nixos/system/locale.nix`, so these just need to be set on the
game's process. Proton-GE inherits them and feeds the correct codepage to the
game. Set per-game, not globally: you don't want every title in a JP locale.

---

## Proton rendering backend

```
PROTON_USE_WINED3D=1
```
**What it does:** Replaces DXVK/VKD3D (Vulkan) with WineD3D (OpenGL) for
Direct3D translation. Slower but more compatible, so use it for old games that
crash, render black/white, or have broken effects under DXVK. Common for older
RPG Maker (RGSS / Direct3D8) and DirectDraw-era VNs.

```
PROTON_NO_D3D11=1
```
```
PROTON_NO_D3D12=1
```
**What it does:** Disable a specific Direct3D version so the game falls back to
an older renderer. Needed for games that misdetect capabilities.

```
PROTON_ENABLE_NVAPI=1
```
**What it does:** Exposes NVIDIA NVAPI (DLSS, Reflex, GPU info). Relevant on the
**laptop's RTX 4070** when routing a game to the dGpu; harmless/ignored on AMD.

```
DXVK_ASYNC=1
```
**What it does:** Async shader compilation to reduce first-run stutter. Already
set globally in `gaming.nix`, but useful to know per-game.

---

## Force XWayland (wrapper command)

When a game or its launcher misbehaves under native Wayland (split/white child
windows, broken cursor, input focus issues), force it onto XWayland.

**Wrapper command field:**
```
/usr/bin/env -u WAYLAND_DISPLAY
```
In Heroic's split wrapper UI: Wrapper = `/usr/bin/env`, Arguments = `-u WAYLAND_DISPLAY`.

**What it does:** Unsets `WAYLAND_DISPLAY` for the game process only, so it can't
find a Wayland socket and falls back to XWayland. Does not affect the rest of
the session.

**Env-var alternative (Proton's native Wayland driver):**
```
PROTON_ENABLE_WAYLAND=0
```
```
PROTON_ENABLE_WAYLAND=1
```
`0` forces XWayland; `1` opts into Proton 9+/GE experimental native Wayland.
Prefer `PROTON_ENABLE_WAYLAND=0` over the wrapper for pure-Proton games; use the
`env -u` wrapper for native/non-Proton launchers.

---

## RPG Maker games

RPG Maker comes in two different runtimes, so identify which before tweaking.

### RPG Maker 2000/2003, XP, VX, VX Ace (RGSS, old and Windows-only)
Use a JP locale + WineD3D; these use DirectDraw / Direct3D8 which DXVK handles
poorly, and most raw releases are Shift-JIS.
```
LANG=ja_JP.UTF-8
```
```
LC_ALL=ja_JP.UTF-8
```
```
PROTON_USE_WINED3D=1
```
**Notes:** If text boxes are blank, the game's bundled RTP fonts may be missing:
the `ipafont` / `kochi-substitute` fonts in `theme/fonts.nix` cover most cases.

### RPG Maker MV / MZ (NW.js, Chromium-based)
These are basically packaged web apps. If they hang on a black screen or crash
on the GPU process, disable the sandbox / GPU as **launch arguments** (not env):
```
--no-sandbox
```
```
--in-process-gpu
```
**Notes:** Many MV/MZ games ship a native Linux build, so prefer that over Proton
when available. Locale env vars are unnecessary (UTF-8 native).

---

## esync / fsync (threading & crashes)

```
PROTON_NO_ESYNC=1
```
```
PROTON_NO_FSYNC=1
```
**What it does:** Disable esync/fsync synchronization primitives. Default-on for
performance; turn off only to diagnose random crashes, hangs, or audio/thread
issues in older or buggy games.

---

## Audio crackle / stutter

```
PULSE_LATENCY_MSEC=60
```
**What it does:** Raises the PulseAudio/PipeWire buffer latency to stop crackling
in games that request too-small audio buffers.

---

## Performance wrappers

Put in the **Wrapper command** field (Heroic/Lutris) or before `%command%` (Steam):
```
gamemoderun
```
```
mangohud
```
```
mangohud gamemoderun
```
**What they do:** `gamemoderun` applies Feral GameMode (CPU governor, scheduling
tweaks); `mangohud` overlays FPS/frametime/temps. Both packaged in `gaming.nix`.

```
nix-performance
```
**What it does:** Clears `LD_PRELOAD` (drops the Steam overlay), then runs the
game under `gamemoderun` with MangoHud (left off inside gamescope), and on the
laptop also through `nvidia-offload` so it lands on the RTX 4070. It also sets
`PROTON_FSR4_UPGRADE=1` on the desktop and `PROTON_DLSS_UPGRADE=1` on the laptop, unless the launch options already set a
value (`=0` turns it off, a version string pins one). Defined in
`home-manager/programs/gaming/nix-performance.nix`. Anything that preloads a
library has to come before it, or the clear wipes it:
`tml-prelaunch nix-performance %command%` (tml-prelaunch clears it too, so it
goes first). Screenshots, invites, Remote Play Together and in-game purchases
need the overlay; drop the wrapper for games that use them.

```
nix-gamescope
```
**What it does:** Runs the game fullscreen in gamescope, with `nix-performance`
applied inside. Nested gamescope can't detect the display and falls back to
1280x720, so the wrapper asks niri (or Hyprland) for the focused monitor's mode
and passes it as both the output and game size, plus the refresh rate as the
frame cap. A game set to a lower resolution gets scaled up to fill the screen.
Extra gamescope flags go before a `--` and override the detected ones:
`nix-gamescope -w 1920 -h 1080 -F fsr -- %command%` renders at 1080p and
upscales with FSR1. For the FPS overlay use `nix-gamescope --mangoapp --
%command%` instead of `mangohud`. Defined in
`home-manager/programs/gaming/nix-gamescope.nix`; the always-on flags
(`--rt --expose-wayland`) come from `nixos/gaming/gamescope.nix`. Add
`--force-grab-cursor` per game only if the cursor escapes during mouse-look: it
locks the pointer inside gamescope until you switch workspaces. Wine is forced
onto gamescope's Xwayland (`PROTON_ENABLE_WAYLAND=0`), since its Wayland driver
hangs on gamescope's `--expose-wayland` socket.

```
nix-vn
```
**What it does:** Upscales visual novels with the FSR 1 pass built into
GE-Proton's fullscreen hack. Set the game to **fullscreen** at its own
resolution; Wine renders there and FSR scales it to the monitor. It sets
`PROTON_ENABLE_WAYLAND=0` (the fullscreen hack only exists in Wine's X11
driver), `WINE_FULLSCREEN_FSR=1` and `WINE_FULLSCREEN_FSR_STRENGTH=5`. Strength
runs 0 (sharpest) to 5 (softest), GE-Proton's own default is 2; 5 keeps
sharpening halos off line art and text. A launch-option value wins:
`WINE_FULLSCREEN_FSR_STRENGTH=3 nix-vn %command%`. Per the GE-Proton README
(checked 2026-09-24) it only works on Vulkan paths (DXVK, VKD3D-Proton), so
DirectDraw-era titles or games run with `PROTON_USE_WINED3D=1` aren't scaled.
For a 1280x720 VN on a 1440p screen (exactly 2x),
`PROTON_ENABLE_WAYLAND=0 WINE_FULLSCREEN_INTEGER_SCALING=1 %command%` keeps the
art pixel-exact instead. Defined in `home-manager/programs/gaming/nix-vn.nix`.

---

## Debugging

```
PROTON_LOG=1
```
**What it does:** Writes a `steam-<appid>.log` (Steam) or Proton log to `$HOME`
for diagnosing Wine/DXVK errors. Disable when done: it's noisy and slows launch.

```
WINEDEBUG=-all
```
**What it does:** Silences Wine's debug channels for a small performance/log-noise
win once a game is known-good.
