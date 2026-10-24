---
name: game-troubleshooting
description: Diagnose a game that crashes, freezes, won't start or misbehaves on this NixOS setup (Steam/Proton, Heroic, Lutris, Faugus, umu, native Linux games). Use whenever the user says a game crashed, froze, hangs, won't launch, has broken input/audio/graphics, asks for launch options to get logs, or wants a game's Proton log read, even if they only name the game.
---

# Game troubleshooting

Work from evidence: get a log, tell a crash from a hang, change one thing at a time, and
check whether a native engine can run the game before going deep into Wine.

## 1. Start from what's already known

- Check memory for the game (`MEMORY.md` has per-game entries) and the per-game docs
  below. A known fix beats a fresh investigation.
- Note the current launch option before changing it, so it can be restored. Keep any
  wrapper already in it (e.g. the `System40.exe` swap) when adding variables.
- Compatibility tools live in `~/.local/share/Steam/compatibilitytools.d/` and
  `steamapps/common/Proton*`; the log header names the one that actually ran.

## 2. Get a log

| Case | Launch option | Output |
| --- | --- | --- |
| Proton, default | `PROTON_LOG=1 %command%` | `~/steam-<appid>.log`, overwritten each launch |
| Crash detail | `PROTON_LOG=1 WINEDEBUG=+timestamp,+tid,+seh %command%` | exceptions with registers |
| Input/window bugs | `PROTON_LOG=1 WINEDEBUG=+timestamp,+tid,+cursor,+win %command%` | mouse, focus, clipping |
| Native Linux game | `%command% > ~/game.log 2>&1` | stdout/stderr |

- A custom `WINEDEBUG` replaces Proton's default channels (`+loaddll` disappears).
- `+cursor` grows fast and an old log once reached 338 MB: never `cat` a log, grep it,
  and have the user drop `PROTON_LOG` when done. Offer to delete big stale
  `~/steam-*.log` files.
- `WINEDEBUG=-all` silences Wine's channels once a game is known-good.

## 3. Read it

Log lines are `time:tid:class:channel:function`. Find the game's main thread (the one
that loads the exe's DLLs and pumps window messages) and follow it.

Noise to skip (checked 2026-10-12 on GE-Proton9-27):
- `err:ntdll:fill_cpu_override ... WINE_CPU_TOPOLOGY` and `gamemodeauto: dlopen failed`
- `RPC_S_SERVER_UNAVAILABLE` (code `6ba`) from service processes
- `fixme:dwmapi:DwmGetWindowAttribute DWMWA_CLOAKED` spam
- code `40010006` is `OutputDebugString`: the game's own debug text, often Shift-JIS.
  Decode with Python: `bytes(...).decode("cp932")`

**Crash:** an exception like `c0000005` (access violation), `Unhandled exception`, a
`backtrace:` block, or the process exiting. **Hang:** the main thread's lines just stop
while other threads (audio, Wine's input thread) carry on.

## 4. A hang: look at the live process

Ask the user to leave it frozen, then:

```bash
pgrep -a -f '<Game>.exe'                     # the Z:\...\<Game>.exe line is the game
ps -L -o tid,stat,pcpu,wchan:28,comm -p <pid> | sort -k3 -rn | head
```

- Main thread `R` near 100% and silent in the log: a loop in the game's own code.
- Near 0% in `futex_wait`: a deadlock or a wait that never ends.

A live backtrace isn't possible here: `ptrace_scope=1` blocks gdb without root, and
`protontricks -c 'wine winedbg ...'` starts its own wineserver and can't see the game.
Don't spend time on either. Kill the hung game with `kill <pid>` when the user asks,
then confirm the Proton processes are gone.

## 5. Narrow it down, one change at a time

- Windowed vs fullscreen vs `nix-gamescope`.
- Another Proton build. Before suggesting `PROTON_ENABLE_WAYLAND=1`, check the build
  ships the driver: `find <proton>/files/lib -name 'winewayland*'`. GE-Proton9-27 has
  none, so the variable is ignored there (checked 2026-10-12).
- Vanilla vs modded exe, to tell a mod bug from an engine bug.
- Env vars and wrappers by topic (JP locale, rendering backend, XWayland, esync/fsync,
  audio): the Launch Options list in `omni-settings/src/proton.py`.

## 6. Check for a native engine

When a game stays broken under Proton, search for a native reimplementation of its
engine and that project's compatibility list. In this repo:

- xsystem4 (always on eclipse, `machines/eclipse/games/xsystem4/`): Wonderland
  Soft's System 4 (Lance 7, added 2026-10-13 after a freeze on every Proton
  setup). Steam launch option
  `nix-vn-720p xsystem4 "<game dir>" # %command%`: gamescope upscales it with
  the NVL CNN, so the preset must match `ViewWidth`/`ViewHeight` in `System40.ini`.
  Saves go to `~/.xsystem4/<GameName from System40.ini>/<SaveFolder>/`, not the game
  folder; copy them over with the game closed. Keys: F11 fullscreen, Alt+S
  screenshot. Cursor auto-move is patched out.
- `gaming.easyrpg`: RPG Maker 2000/2003.

A 2D game or visual novel that only looks blurry when scaled to the monitor can run
under gamescope with the NVL CNN instead: the `vn-setup` skill.

A new one goes in through the `add-app` skill.

## Per-game notes

| Game or bug | Where |
| --- | --- |
| Launch options for Morimens, Risk of Rain 2, tModLoader, No Rest for the Wicked, Arknights Endfield, Wuthering Waves | `docs/gaming/launch-parameters.md` |
| tModLoader paths and log queries | `docs/personal/gaming/tmodloader-debugging.md` |
| Rocksmith 2014 (Katana DI, RS_ASIO) | `docs/personal/gaming/rocksmith-2014.md` |
| feedBack audio settings, Guitar Pro import | `docs/personal/gaming/feedback.md` |
| Minecraft servers (GTNH, TerraFirmaGreg) | `docs/personal/gaming/minecraft_servers/<pack>/index.md` |

## Afterwards: keep this current

At the end of a debugging session, propose additions to the user:

- A reusable finding (a log pattern, a Proton quirk, a native engine) goes in this file,
  dated, under the matching step. Remove a note once a later version makes it wrong.
- A game-specific fix goes in that game's doc under `docs/gaming/`, or memory if it's
  personal (paths, saves, accounts).
- The repo is public: adult games and studios get a stand-in name (the key is in local
  memory), and nothing adult goes in `README.md`.
