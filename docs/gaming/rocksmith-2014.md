# Rocksmith 2014 on Proton with the Katana

Rocksmith 2014 Edition Remastered (Steam app 221680) reads the guitar from the Katana MkII's dry DI instead of a Real Tone Cable. The chain is Katana DI capture (PipeWire) → PipeASIO (ASIO driver inside Proton) → RS_ASIO (DLL in the game folder) → the game. Set up and verified on the desktop on 2026-10-05: note detection caught every note in a song, including a deliberately wrong one, and custom songs (CDLC) load alongside it.

## What the repo handles

- **`gaming.rocksmith`** gates `shared/modules/home/programs/gaming/games/rocksmith.nix`, which writes `RS_ASIO.ini` into the game folder and `~/.config/pipeasio/config.ini`. Both are read-only symlinks, so the PipeASIO settings panel can't save over them.
- **The Katana's driver priority** is lowered by a WirePlumber rule in `shared/modules/nixos/services/hardware/sound.nix`. See the troubleshooting section for why.

## Manual steps on a fresh install

1. **Install the game** from Steam and set Properties → Compatibility to **Proton 11.0** (Valve's build). Launch it once so Steam creates the prefix at `~/.local/share/Steam/steamapps/compatdata/221680/pfx`.
2. **Install PipeASIO** with its Manager AppImage from the [releases page](https://github.com/M0n7y5/pipeasio/releases) (v1.10.0 on 2026-10-05). Open it, pick Rocksmith 2014 on the Installations tab, tick **Include experimental 32-bit support** (the game is 32-bit), and click Install. It downloads the driver, registers it in the prefix through `umu-run` with the game's own Proton, and checks that both the 64-bit and 32-bit halves load and reach PipeWire. Don't run `pipeasio-register` with the host's `wine` on a Proton prefix: the PipeASIO README warns it rewrites the prefix for the wrong Wine build ([issue #22](https://github.com/M0n7y5/pipeasio/issues/22)).
3. **Set the launch options** to what the Manager prints plus the CDLC enabler override. On 2026-10-05 that was:

   ```
   PROTON_USE_WOW64=1 WINEDLLPATH=/home/warpledge/.local/share/pipeasio/versions/v1.10.0-x86_64-591a0f14a329627e/lib/wine WINEDLLOVERRIDES="winemenubuilder.exe=d;d3dx9_42=n,b;xinput1_3=n,b" %command%
   ```

   The `WINEDLLPATH` directory carries the PipeASIO version, so every PipeASIO update changes this line. Copy the new one from the Manager. `WINEDLLOVERRIDES` in the launch options replaces the session-wide value, so it repeats `winemenubuilder.exe=d` from there. `d3dx9_42` is the CDLC enabler (step 7) and `xinput1_3` is RSMods (step 9).
4. **Unpack RS_ASIO** (`avrt.dll`, `RS_ASIO.dll`) from the [releases page](https://github.com/mdias/rs_asio/releases) into `~/.local/share/Steam/steamapps/common/Rocksmith2014/`. v0.7.5 was current on 2026-10-05. Skip the zip's `RS_ASIO.ini`, the module supplies it.
5. **Edit `Rocksmith.ini`** in the same folder (CRLF line endings, and the game writes this file itself, so it stays unmanaged): `RealToneCableOnly=1` and `EnableMicrophone=0`. Leave `ExclusiveMode=1` and `Win32UltraLowLatencyMode=1` as shipped.
6. **Skip calibration.** At the input selection screen pick **Disconnected**, which gets you to the main menu, then switch the input back to the Real Tone Cable from there. That path skips calibration. Calibration is unusable with this setup (see below) and the input level is already fixed by `RS_ASIO.ini`.
7. **Install the CDLC enabler.** Use the `D3DX9_42.dll` inside CustomsForge's `RS2014-CDLC-Installer.exe` ([Ignition tools page](https://ignition4.customsforge.com/tools/cdlcenabler), v4.0 released 2025-08-12, installer sha256 `b39d1904…a27b0`). It's a .NET app with the DLL embedded, so carve the DLL out instead of running it:

   ```bash
   cd ~/Downloads && nix shell nixpkgs#python3 -c python3 - <<'EOF'
   import struct
   d = open('RS2014-CDLC-Installer.exe', 'rb').read()
   off = d.index(b'This program cannot be run in DOS mode', 100) - 0x4e
   pe = off + struct.unpack_from('<I', d, off + 0x3c)[0]
   n, opt = struct.unpack_from('<H', d, pe + 6)[0], struct.unpack_from('<H', d, pe + 20)[0]
   end = max(sum(struct.unpack_from('<II', d, pe + 24 + opt + 40 * i + 16)) for i in range(n))
   open('D3DX9_42.dll', 'wb').write(d[off:off + end])
   EOF
   ```

   The result is 253952 bytes, sha256 `aadb1047…b40e5`, and belongs next to `Rocksmith2014.exe`. Don't use the newer build from the [RSCDLCEnabler-TooManyCoresFix](https://github.com/Lovrom8/RSCDLCEnabler-TooManyCoresFix) repo; see troubleshooting.
8. **Add songs** from [CustomsForge Ignition](https://ignition4.customsforge.com/) (free account). Take the PC files (`*_p.psarc`) and put them in `Rocksmith2014/dlc/cdlc/`. When a song comes in a `_DD_` and a plain version, take only the DD one: it carries the Dynamic Difficulty levels, and installing both lists the song twice.
9. **RSMods (optional).** [RSMods](https://github.com/Lovrom8/RSMods) v1.2.8.4 (`RS2014-Mod-Installer.exe`, released 2026-08-15) runs as `xinput1_3.dll`, so it sits next to the CDLC enabler instead of replacing it. Run the installer in the game's prefix, close the game first:

   ```bash
   protontricks-launch --appid 221680 ~/Downloads/RS2014-Mod-Installer.exe
   ```

   Point it at `S:\steamapps\common\Rocksmith2014` (`S:` is the Steam library). It installs `xinput1_3.dll` and an `RSMods/` folder holding the settings app, which reopens the same way with `RSMods/RSMods.exe`. Settings land in `RSMods.ini` next to the game (CRLF). The app saved every hotkey blank on 2026-10-05, so set these by hand afterwards; keys take Windows virtual-key names from `keyMap` in RSMods' `DLL/Settings.hpp`:

   ```ini
   ToggleLoftKey = VK_HOME
   LoopStartKey = VK_PRIOR
   LoopEndKey = VK_NEXT
   RewindKey = VK_INSERT
   ```

   Under `[Toggle Switches]`, `RemoveFingerprints = on` hides the finger numbers (the README doesn't list it, `Settings.cpp` does) and `ToggleLoft = on` makes the Home key work. The other toggle and setting names are all read in `DLL/Settings.cpp`. The app's "GUI only" options rewrite `cache.psarc` and left no backup in the game folder or the prefix; Steam's **Verify integrity of game files** restores it.

The AUX DI pair the module points PipeASIO at is `alsa_input.usb-BOSS_KATANA-01.HiFi__Line4__source`. A different interface means a different `input_device` in the module and its own input level in `SoftwareMasterVolumePercent`.

## Troubleshooting

**"A debugger has been found running in your system"** on launch came from GE-Proton11-7. Valve's Proton 10.0-4 and 11.0 (with WOW64) don't trigger it.

**The game closes about half a second after its window opens** on Proton 11.0 without `PROTON_USE_WOW64=1`. It isn't ntsync: `PROTON_NO_NTSYNC=1` (the variable Valve's Proton 11 reads, unlike `PROTON_USE_NTSYNC`) gave the same exit. Adding `PROTON_USE_WOW64=1` fixed it, and PipeASIO's 32-bit driver needs that mode anyway.

**The first second of audio loops and nothing else plays.** The Katana's capture node (`alsa_input.hw_KATANA_0`) shipped with `priority.driver` 2100, the highest on the system, so it clocked every graph it joined at its only rate, 44.1 kHz, including the onboard output. RS_ASIO asks PipeASIO for 48 kHz and the stream stalled after its first buffers (visible in `RS_ASIO-log.txt` as buffer switches that stop). The WirePlumber rule in `sound.nix` drops it to 1000, under the onboard output's 1009. Check with `pw-dump`: the `Rocksmith2014` node's `node.driver-id` should be the onboard output, not the Katana.

**Calibration drives the input to nothing.** The game sets its input volume through RS_ASIO's endpoint volume. During the palm-mute step it walked that volume down to the 0.01 floor (one `SetMasterVolumeLevelScalar` line per step in `RS_ASIO-log.txt`) and the following loud step never brought it back, so the meter flatlined. `EnableSoftwareEndpointVolumeControl=0` on `[Asio.Input.0]` makes RS_ASIO ignore those calls. The meter still reads nothing after that change, which is why step 6 skips calibration.

**Input level.** Hard strums on the Katana DI peak around 0.06 of full scale. `SoftwareMasterVolumePercent=490` (RS_ASIO accepts 0 to 1000, per `Configurator.cpp`) brings hard strums to roughly half scale. If notes clip or sound crunchy, lower it; if quiet notes go unread, raise it. Measure a source instead of guessing:

```bash
timeout 5 pw-record --target alsa_input.usb-BOSS_KATANA-01.HiFi__Line4__source --channels 2 /run/user/1000/strum.wav
nix shell nixpkgs#sox -c sox /run/user/1000/strum.wav -n remix 1 stat
```

Record the `Line3`/`Line4` sources separately. A 4-channel `pw-record` of `alsa_input.hw_KATANA_0` maps the AUX channels onto FL/FR/RL/RR and downmixes them, which makes channels 3 and 4 look silent when they aren't.

**Custom songs don't show up, and the enabler's console says `Failed to change memory protection. Status: 0xC0000001`.** That's the GitHub build of the enabler (commit `b88101f`, 2026-08-15). It detects Wine and switches to `VirtualProtect`, which fails inside the game process before reaching Wine (a `PROTON_LOG=+virtual` trace shows the enabler thread's `NtQueryVirtualMemory` on `0x5596fa` and no `NtProtectVirtualMemory` after it). Same result on Proton 10.0 without WOW64. The CustomsForge v4.0 build from step 7 works on Proton 11.0 with WOW64 and on Proton 9.0-4. The older DLL linked from the [devroom.io CachyOS guide](https://www.devroom.io/2025/12/02/rocksmith-2014-on-cachyos-arch-linux/) needs the Cherub Rock DLC, which Steam no longer sells.

**RSMods features may not apply.** RSMods' `DLL/MemUtil.cpp` takes the same `VirtualProtect` path under Wine as the GitHub enabler build above. On 2026-10-05 it loaded alongside the CustomsForge enabler without breaking custom songs, but whether its in-game patches (finger numbers, rewind, looping) take effect wasn't checked yet.

**No audio after switching Proton versions.** Running the prefix under another Proton and back rebuilds its registry and drops PipeASIO's registration, while the driver files stay. `RS_ASIO-log.txt` then shows `requesting ASIO driver: PipeASIO` followed by `failed`. Run the PipeASIO Manager's **Repair** on the game.

**Don't pick Microphone at input selection.** RS_ASIO's `[Asio.Input.Mic]` has no driver, so it's a silent device. `EnableMicrophone=0` removes the option.
