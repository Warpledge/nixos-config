# feedBack

feedBack (`gaming.feedback`, `modules/home/programs/gaming/games/feedback.nix`)
is a guitar rhythm game that plays Guitar Pro tabs. The module wraps upstream's
rolling `nightly` AppImage, and its comment explains the hash-mismatch bump
signal. Set up on 2026-08-30 with the Katana MkII DI as input; the device's
quirks are in `docs/audio/katana-mk2.md`.

## Audio settings that work

```
Input   ALSA · "KATANA, USB Audio; Front output / input" · channel 3
Output  ALSA · Default   (PipeWire, not the KATANA entry)
Rate    44100 Hz         Buffer 128 samples
```

Output has to be `Default`: the Katana's `front:` device refuses 2-channel
playback, and going through PipeWire avoids its fixed 4-channel map. The
Buffer Size dropdown has no effect; the device stays at period 128 and buffer
512 whatever it's set to (checked in `/proc/asound/card2/pcm0c/sub0/hw_params`).

## Importing a Guitar Pro tab

This order was the only one that worked as of 2026-08-30:

1. Import the tab without audio. Attaching audio at import starts auto-sync.
2. Attach the audio afterwards in the Song Editor.
3. Set a constant **Offset**.

Don't let auto-sync run on a tab whose tempo map imported correctly. On dense
material it locked onto a fraction of the tempo (64 and 79 BPM against real
tempos of 130 to 300) and wrote entries at negative times. Even when it lands
close, it changes tempos per section to stretch the chart, so subdivisions fall
on the wrong beats.

The audio render of a GP file runs longer than the converted chart by a fixed
lead-in plus a decay tail (for one song: 11.8 s + 255.13 s + 3.5 s = 270.5 s),
so a single constant offset lines them up; there's no drift.

## Other traps

- The library's **Upload** button takes only `.feedpak` and `.sloppak`. Raw
  `.gp*` files go through the importer, and a folder of tabs scans as 0 songs.
- Loose-folder songs need `audio.wem` plus an arrangement XML, the same shape
  as Rocksmith's format.
- The bundled yt-dlp gets 403 errors from YouTube. Download with the system
  `yt-dlp` (in `utilities.nix`) and use Upload File.
- Each Replace Audio adds a stem file without removing the old one, so packs
  grow quickly.
