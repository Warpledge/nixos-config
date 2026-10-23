# Boss Katana MkII as an Audio Interface

The Katana MkII (USB `0582:01d8`, ALSA card `KATANA`) is the desktop's guitar
input. Verified against the live device on 2026-08-30 unless a later date is
given.

- **44100 Hz only.** `/proc/asound/card2/stream0` lists one altset with
  `Rates: 44100`, so a client asking for 48 kHz fails or gets resampled.
- **Four fixed channels both ways** (`chmap-fixed = FL,FR,FC,LFE`). There's no
  2-channel altset.
- **`front:CARD=KATANA,DEV=0` refuses 2-channel playback**: `aplay` reports
  `Channels count non available`. Capture works when the client asks for four
  channels. For playback use `surround40:CARD=KATANA,DEV=0` or `plughw:`, or
  send it through PipeWire's default output.
- **The dry guitar DI is on capture channels 3 and 4.** PipeWire splits the
  stream into `Line3__source` (channels 1 and 2, the amp's processed signal)
  and `Line4__source` (channels 3 and 4, the dry DI).
- **No ALSA mixer controls.** `amixer -c KATANA` shows only channel maps; the
  level is the physical knob.
- **The DI is quiet.** Hard strums peak around 0.06 of full scale on the
  `Line4` source, so apps need their own input boost (Rocksmith's is in
  `docs/personal/gaming/rocksmith-2014.md`).
- **It used to clock every graph it joined.** Its capture node
  (`alsa_input.hw_KATANA_0`) ships with `priority.driver` 2100, the highest on
  the system, which forced 44.1 kHz on 48 kHz clients. Since 2026-10-05 a
  WirePlumber rule in `modules/nixos/services/hardware/sound.nix` sets it to
  1000, under the onboard output's 1009.

PipeWire allows only 48 kHz by default (`default.clock.allowed-rates`), so the
Katana's stream is always resampled. An app that checks whether its input and
output share a rate may refuse it. The repo doesn't change this as of
2026-10-14; if an app needs it, this lets the graph run at either rate:

```nix
services.pipewire.extraConfig.pipewire."10-rates" = {
  "context.properties"."default.clock.allowed-rates" = [44100 48000];
};
```

To measure a source, record `Line3` or `Line4` on its own. A 4-channel
`pw-record` of `alsa_input.hw_KATANA_0` downmixes the AUX channels and makes
channels 3 and 4 look silent.
