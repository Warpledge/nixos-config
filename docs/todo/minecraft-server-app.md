# Dedicated Minecraft server app

**Goal:** a standalone app with its own interface for running the modded servers on the laptop, instead of the small Servers page in NixOS Settings.

Added 2026-10-21. Future project, nothing started.

## Why

The Servers page only shows status and offers stop, console and log, which is enough for now. A separate app makes sense once the server needs more than that, and keeps NixOS Settings about settings. `quick-todos.md` has the in-app version of this idea (a custom interface on the Servers tab, docs and the TerraFirmaGreg server removed); pick one of the two before starting.

## What's already in the repo

- `machines/legion/minecraft-servers/{gtnh-server,tfg-server}.nix` write a `gtnh` and a `tfg` command each. With no argument it starts the server in a detached tmux session (`tmux new-session -d`) and attaches; `status`, `stop` and `log` do the rest. Stop sends `/stop` to the session.
- Each server file writes `~/.config/nixos-settings/servers/<name>.json`, which `modules/home/programs/system/nixos-settings/src/servers.py` reads to list it. A new app can read the same files.
- `mcservers.nix` is the fzf picker over the hardcoded pack list.
- The server keeps running after NixOS Settings, the terminal or the session closes, since tmux holds it and nothing sets `KillUserProcesses`. Nothing starts it again after a reboot or a crash.

## What it could have

- The live console inside the window, with a command line, instead of a terminal attached to tmux
- Buttons for common commands (save, whitelist, broadcast a restart warning, stop)
- A player list and chat, over RCON
- TPS, RAM and CPU over time
- World backups and restore
- Editing `server.properties` and the mod list

## Steps left

1. Decide between this and the in-app version in `quick-todos.md`.
2. Consider moving each server to a systemd service first, with tmux kept for the console, so it starts at boot and restarts after a crash. Either interface would then read the service's state.
3. Pick the toolkit (GTK4/libadwaita in Python like NixOS Settings, or something else) and how it reaches the console: tmux `capture-pane`/`send-keys`, or RCON.
4. Package it as a home module for the legion machine, gated the way `minecraft-servers/` is.
