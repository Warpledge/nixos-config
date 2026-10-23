# Dedicated Minecraft server app

**Goal:** a standalone app with its own interface for running the modded servers on the laptop.

Added 2026-10-21. Future project, nothing started.

## Why

Omni Settings' Servers tab (status, stop, console and log) was removed on 2026-10-21 to keep that app about settings, so the servers are run from a terminal for now. The first version leaves out the TerraFirmaGreg server.

## What's already in the repo

- `machines/legion/minecraft-servers/{gtnh-server,tfg-server}.nix` write a `gtnh` and a `tfg` command each. With no argument it starts the server in a detached tmux session (`tmux new-session -d`) and attaches; `status`, `stop` and `log` do the rest. Stop sends `/stop` to the session.
- The removed Servers page (`src/servers.py`, git history before 2026-10-21) listed the servers from a JSON file each server module wrote, and called the same commands.
- `mcservers.nix` is the fzf picker over the hardcoded pack list.
- The server keeps running after the terminal or the session closes, since tmux holds it and nothing sets `KillUserProcesses`. The command restarts it after a crash (12 s countdown, inside tmux), but nothing starts it after a reboot.

## What it could have

- The live console inside the window, with a command line, instead of a terminal attached to tmux
- Buttons for common commands (save, whitelist, broadcast a restart warning, stop)
- A player list and chat, over RCON
- TPS, RAM and CPU over time
- World backups and restore
- Editing `server.properties` and the mod list

## Steps left

1. Consider moving each server to a systemd service first, with tmux kept for the console, so it starts at boot. The app would then read the service's state.
2. Pick the toolkit (GTK4/libadwaita in Python like Omni Settings, or something else) and how it reaches the console: tmux `capture-pane`/`send-keys`, or RCON.
3. Package it as a home module for the legion machine, gated the way `minecraft-servers/` is.
