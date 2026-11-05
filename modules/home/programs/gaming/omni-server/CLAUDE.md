# Omni Server

<!-- Claude Code loads this file when it reads a file in this folder. -->

Omni Server (`gaming.omniServer`) runs Minecraft servers from their own folders, with a QML window (Quickshell) and a Python backend. Omni Settings' parts are built into it (`shared` in `default.nix`), so a change to `Theme`, `Backend`, `Field` and the rest reaches both apps. Those files must not depend on `OmniView` or anything else this app doesn't install.

## How a server runs

Three user unit templates in `default.nix`, instanced by server id:

- `omni-server@.service` is the server itself, with no terminal: closing the window or restarting DMS doesn't touch it. `src/runner.py` `exec`s the JVM, so the main PID is the JVM. `ExecStop` sends `stop` and waits, so a logout or shutdown saves the world. Output goes to `~/.local/state/omni-server/<id>/console.log`; `console.log.1` is the last run's. `X-SwitchMethod=keep-old` keeps a rebuild from restarting a running server.
- `omni-server@.socket` is stdin, a FIFO at `$XDG_RUNTIME_DIR/omni-server/<id>.stdin`. `PartOf` stops it with the server, or a stray write would start the server again.
- `omni-server-monitor@.service` (`src/monitor.py`) tails the console, polls stats, samples the JVM, writes the history (`history.db`, `src/history.py`), and runs quick command sequences and scheduled restarts, so all of those work with the window closed. It publishes JSON lines on `<id>.sock`, which `watch` in `src/api.py` relays to the window on stderr (`Backend.stream`).

Linger (`modules/nixos/system/user/user.nix`, on for anyone with the toggle) keeps servers up through logout and makes Start at boot work. Start at boot is the instance's symlink in `~/.config/systemd/user/default.target.wants/` (`servers.set_boot`), and Restart on crash is a drop-in in `~/.config/systemd/user/omni-server@<id>.service.d/`.

Each server's config is `~/.config/omni-server/servers/<id>.json`; nothing about a server goes in the repo. The only files the app writes in a server's folder are `eula.txt`, `server.properties`, the whitelist, op and ban JSON, `mods/` renames and added jars, and `backups/`.

## Gotchas

- **`omni-server@.service` has no `Install` section.** With `WantedBy`, home-manager's switch tries to start the bare template and the rebuild fails with "missing the instance name". `systemctl add-wants` isn't the way around it either: it also links `default.target` to a store path in `~/.config/systemd/user/`.
- **The monitor is ordered `Before` the server, not `After`.** A stop runs in reverse order, so `After` stops the monitor first and it misses the shutdown lines that name the dimensions.
- **Never send two RCON packets at once.** 1.7.10 reads one packet per socket read and drops the connection otherwise; `src/rcon.py` only sends its closing request after a full-sized reply packet. Long replies come back split at 4096 bytes with nothing marking the end.
- Stats go over RCON because stdin polling would write `forge tps` to the server's log. Commands a person runs always go through stdin, since that's the main thread on every version; RCON runs on its own thread on plain 1.7.10, and Hodgepodge's `fixRconThreading` is why it's safe on GTNH. With RCON off, polls go through stdin every 30 s, with their lines hidden from the console view.
- 1.7.10's `forge tps` names no dimensions, and its RCON reply has no line breaks (`src/logparse.py`). The names come from pairing the last poll's order with the `Saving chunks` lines at a clean stop (`pair_dim_names`), stored as `dimAuto`; a person's renames in `dimNames` win. Checked 2026-11-04 on GTNH 2.9.0: TConstruct's log gives the Twilight Forest as dim 7, and the pairing agrees.
- Chat and joins are only read from Minecraft's own logger (no tag, or a `net.minecraft`/`minecraft` tag): plenty of mods log `[Name] text`, which looks like `say`.
- A server can rewrite `server.properties` while running, so edits made then are held in `pending-properties.json` and applied by `ExecStartPre`. That file and `server.properties` hold the RCON password, so both are owner-only.
- Anything sent to stdin is flattened to one line in `servers.send`, as a newline would start a second command, and player names must match `servers.PLAYER`. Console, chat and names render as `Text.PlainText`, since players write them.
- A pack's own start script usually loops forever, which defeats Stop; the app launches the JVM itself from `servers.detect`'s target, and Custom command is the way around that.

## Testing

Build `.#nixosConfigurations.<machine>.config.home-manager.users.<user>.omni-server.package`. Before a rebuild, copy the three units from that user's `home-files` build (`.config/systemd/user/`) into `$XDG_RUNTIME_DIR/systemd/user/`, run `systemctl --user daemon-reload` and delete them afterwards. Those units never pass through a home-manager switch, so after changing a unit also run `sd-switch --dry-run --old-units <current> --new-units <new>` on the two `home-files` builds' `.config/systemd/user`. The backend runs from the shell as `bin/omni-server-backend <command> '<json>'`. For renders, copy the built `share/omni-server/qml` to a scratch folder, add a `zz*.qml` holding a `ServerView` that saves `grabToImage` shots, and run it with `QT_QPA_PLATFORM=offscreen qs -p`.
