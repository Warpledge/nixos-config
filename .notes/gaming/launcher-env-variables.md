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
game. Set per-game, not globally — you don't want every title in a JP locale.

---

## Proton rendering backend

```
PROTON_USE_WINED3D=1
```
**What it does:** Replaces DXVK/VKD3D (Vulkan) with WineD3D (OpenGL) for
Direct3D translation. Slower but more compatible — use for old games that
crash, render black/white, or have broken effects under DXVK. Common for older
RPG Maker (RGSS / Direct3D8) and DirectDraw-era VNs.

```
PROTON_NO_D3D11=1
```
```
PROTON_NO_D3D12=1
```
**What it does:** Disable a specific Direct3D version so the game falls back to
an older renderer. Occasionally needed for games that misdetect capabilities.

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

RPG Maker comes in two very different runtimes — identify which before tweaking.

### RPG Maker 2000/2003, XP, VX, VX Ace (RGSS — old, Windows-only)
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
**Notes:** If text boxes are blank, the game's bundled RTP fonts may be missing —
the `ipafont` / `kochi-substitute` fonts in `theme/fonts.nix` cover most cases.

### RPG Maker MV / MZ (NW.js — Chromium-based)
These are basically packaged web apps. If they hang on a black screen or crash
on the GPU process, disable the sandbox / GPU as **launch arguments** (not env):
```
--no-sandbox
```
```
--in-process-gpu
```
**Notes:** Many MV/MZ games ship a native Linux build — prefer that over Proton
when available. Locale env vars are usually unnecessary (UTF-8 native).

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

---

## Debugging

```
PROTON_LOG=1
```
**What it does:** Writes a `steam-<appid>.log` (Steam) or Proton log to `$HOME`
for diagnosing Wine/DXVK errors. Disable when done — it's noisy and slows launch.

```
WINEDEBUG=-all
```
**What it does:** Silences Wine's debug channels for a small performance/log-noise
win once a game is known-good.
