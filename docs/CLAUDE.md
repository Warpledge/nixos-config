# Reference Notes

<!-- Claude Code loads this file when it reads a file in this folder. -->

Security/privacy notes live under `docs/security/`:

- `security/blocklists.md` — uBlock Origin filter lists
- `security/ublock-filters.md` — custom uBlock cosmetic filters (paste into uBlock → My Filters)
- `security/mullvad.md` — DataPacket-hosted relays read as London to registry-based services (Steam); pick a Tzulo relay in the same city
- `security/apparmor.md` — the per-app AppArmor profiles: what each attaches to, reading `apparmor="ALLOWED"` log lines, moving a profile to enforce, and what breaks first when you do

Beginner guides to using this setup day to day live under `docs/guide/`, shown in file name order as the Guides section of Omni Settings' Docs tab. Keep them in step when a page, button, keybind or `nixm` command they describe changes; links to repo files open in the user's text editor (`{user}` and `{machine}` stand for the login and machine):

- `guide/01-start-here.md` to `guide/10-local-models.md` — the terms, Omni Settings, installing apps, updates and versions, the desktop and keybinds, backups and git, `nixm`, recovering from a failed rebuild, the `Mod+A` side rail, and tuning local AI models on the Local Models page

Game notes live under `docs/gaming/` (the `game-troubleshooting` skill indexes them; Omni Settings' Docs tab shows the top-level `gaming/*.md` notes):

- `gaming/launch-parameters.md` — per-game launch options and why each is set. Common env vars and wrappers are on Omni Settings' Docs → Launch Options page (`omni-settings/src/proton.py`) and in `nixm launch-params`

nixpkgs update notes live under `docs/nixpkgs/`:

- `nixpkgs/disabled-packages.md` — packages switched off because a flake update broke them, with the date, the nixpkgs rev and how to tell a fix has landed. **Add a row whenever an update forces a package off, and remove it on re-enable.** The `disable-package` skill does both.

Window manager notes live under `docs/wm/`:

- `wm/niri-xdg-portals.md` — why `xdg-desktop-portal-gnome` drops to Settings-only when `GDK_BACKEND` is set, how niri-flake hides the system portal backends, and the `busctl` health check

warpledge's own notes, for hardware and games only they use, live under `docs/personal/`. On anyone else's machine they're reference at most, never that person's setup:

- `personal/security/android-quic-vpn-leak.md` — QUIC VPN bypass (CVE, May 2026): mitigation via `adb shell device_config put tethering close_quic_connection -1`; re-apply after Android updates
- `personal/gaming/tmodloader-debugging.md` — tModLoader paths and log locations
- `personal/gaming/rocksmith-2014.md` — Rocksmith 2014 on Proton 11 + WOW64 with the Katana DI via PipeASIO and RS_ASIO: the manual install steps the `gaming.rocksmith` module can't do, the Katana driver-priority stall, why calibration is skipped, which CDLC enabler build works (the CustomsForge v4.0 one, not the newer GitHub build), and the optional RSMods setup
- `personal/gaming/feedback.md` — feedBack's working audio settings and the Guitar Pro import order (import without audio, constant offset, never auto-sync)
- `personal/gaming/minecraft_servers/{GTNH,TerraFirmaGreg-Modern}/` — each pack has `index.md` listing its sub-files (server setup, mods, config tweaks, etc.). **Update the relevant sub-file when that pack's config, mods, or settings change.** The matching declarative modules live at `machines/legion/minecraft-servers/{gtnh-server,tfg-server}.nix` (add a new server by creating a `.nix` there, importing it in that dir's `default.nix`, and adding a line to the hardcoded pack list in `mcservers.nix`, the fzf picker that names each pack with its version and dispatches to that server's command)
- `personal/audio/katana-mk2.md` — the Katana MkII as an interface: 44.1 kHz only, four fixed channels, dry DI on capture channels 3 and 4, `front:` refusing 2-channel playback, the driver-priority rule
- `personal/android/debloat/Lenovo-Idea-Tab-Pro/` — `index.md` (full redo procedure: never-remove list, install-replacements-first ordering, PMS flush, reboot test, privacy settings) + `removal-list.txt` (the 131 verified-safe packages). **A ZUI OTA restores every stock package, so this gets redone after each system update** with the `android-debloat-redo` skill.
- `personal/local/local-binary-installs.md` — the `~/.local/opt` wrapper pattern for prebuilt third-party bundles kept out of git; restore steps for fresh installs / the laptop. **Add an entry here for each new local app.**
- `personal/local/appimage-wraps.md` — the `appimageTools.wrapType2` pattern for upstream AppImages. Hash-pinned into the store, so nothing to restore by hand; covers the per-app `Exec`/icon fixups, a non-executable `AppRun`, a DwarFS payload `appimageTools.extract` can't open (unpack with `dwarfsextract`), how to get a new hash when `nix store prefetch-file` hits the daemon's DNS timeout, building one module without a rebuild, and blank text in a Chromium-based wrap (stale GPU shader caches in its profile).
