# feedBack

feedBack (`gaming.feedback`, `modules/home/programs/gaming/games/feedback.nix`)
is a guitar rhythm game that plays Guitar Pro tabs. The module wraps upstream's
rolling `nightly` AppImage, and its comment explains the hash-mismatch bump
signal. Set up on 2026-08-30 with the Katana MkII DI as input; the device's
quirks are in `docs/personal/audio/katana-mk2.md`.

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
