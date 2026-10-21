# Test HDR in the Steam gamescope session

**Goal:** play games in HDR on the Dell AW2725D through Steam's gamescope session, since niri has no HDR output.

Added 2026-10-15.

## What's already in the repo

- `modules/nixos/gaming/steam.nix` turns on `programs.steam.gamescopeSession` and passes it `--hdr-enabled` (added 2026-10-15). The session's entry is named Steam and runs `steam-gamescope`.
- niri 26.04 has no color-management protocol: its binary has no `wp_color_manager_v1` (checked 2026-10-15).
- The CachyOS 7.2.8 kernel's amdgpu module has none of the `AMD_PLANE_*` color properties (checked 2026-10-15). Without them, gamescope still outputs HDR but composites every frame with Vulkan instead of handing planes to the display hardware (DeepWiki's summary of gamescope's `src/Backends/DRMBackend.cpp`), which costs some GPU time per frame.
- Hyprland, the other HDR route (its `Mod+H` bind ran `toggle_hdr`), was removed on 2026-10-21; it's on the `hyprland-backup` branch.

## Steps left

1. Rebuild, log out, and pick Steam in the DMS greeter.
2. Check which monitor the session took. If it's the LG (DP-3), add `"--prefer-output" "DP-2"` to `gamescopeSession.args`.
3. Check the refresh rate under Steam's Settings → Display. niri runs DP-2 at 279.961 Hz, a mode `niri msg outputs` doesn't mark as the panel's preferred one, so gamescope may pick a lower rate; `gamescope --help` lists the output mode flags.
4. Turn on HDR under Settings → Display, then start a game that has an HDR option.
5. If DirectX games don't offer HDR, set `DXVK_HDR = "1";` in `programs.steam.gamescopeSession.env`. It makes DXVK report Windows HDR mode as on, which many games check before they show HDR options (`dxgi.enableHDR` in `dxvk.conf`).
6. To leave, quit Steam; the session ends when Steam exits.
7. Once HDR works, or turns out not to, delete this file.

## Sources

- gamescope DRM backend: https://github.com/ValveSoftware/gamescope/blob/master/src/Backends/DRMBackend.cpp
- DXVK's `dxvk.conf`: https://github.com/doitsujin/dxvk/blob/master/dxvk.conf
