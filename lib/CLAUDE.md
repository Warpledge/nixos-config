# Settings and shared library

<!-- Claude Code loads this file when it reads a file in this folder. -->

## How the settings files are read

Two kinds of settings file, each with a template that lists every setting: **`machines/_template/settings.nix`** (one per computer) and **`users/_template/settings.nix`** (one per person). A setting a file leaves out takes the template's value with every true/false turned off, so a new toggle never breaks someone else's machine. `settings.nix` here stops evaluation with a message naming the file on a misspelt setting, a wrong kind of value, an unknown choice, or a missing `users/<name>/`, `stateVersion` or admin main user. Read the templates directly; don't trust this file to stay in sync.

Module arguments:

- NixOS modules get `machine` (the machine's settings plus `name`, `hostName`, `flakePath` and `mainUser`, filled in, and each user's final settings in `machine.users.<name>`) and `anyUser` (each true/false user setting, true when any user on the machine has it on). An app with a system-side piece (an AppArmor profile, Steam, FlareSolverr, the Nautilus extension, the Japanese IME) loads on `anyUser.<app>`.
- Home modules get `machine` and `user`, that user's settings. Home routers take `user` as a plain first argument (`modules/home/CLAUDE.md`).

## Settings that need more than their template comment

- `flakePath` (null: `/etc/nixos-config`): `system/user/config-repo.nix` gives every admin write access through a default ACL and sets git's `safe.directory`; skipped for a path under `/home/`.
- `windowManager`: one per machine, since the greeter and portal setup are per compositor.
- `gpu.*`: `services/hardware/gpu.nix`; null on a machine whose own `hardware/gpu.nix` does it.
- `admin = false`: no wheel and no docker group.
- `defaultApps.*`: choices, `.desktop` ids and launch commands live in `default-apps.nix`, which `mime.nix`, `terminal-exec`, `youtube-dispatch`, niri's app binds and Omni Settings read through its `forUser`; a pick whose app toggle is off falls to the first of its kind that's on. `mimeapps.list` is forced, so DMS's default-app picker doesn't survive a rebuild: change defaults here.
- `steamGames`: `home/programs/gaming/steam-games.nix` hands it to `steam-games-apply` (`nixos/gaming/steam-games-apply.py`), which writes it into Steam's `localconfig.vdf` and `config.vdf` only while Steam is closed (the client is `steamrt64/steam` or the older `ubuntu12_32/steam`); the Steam package's `extraPreBwrapCmds` runs it again before Steam starts, except for `steam -shutdown`. Each run compares with Steam's files, since Steam rewrites them on exit, and sends a notification naming the games it wrote, or those left waiting while Steam is open; `--pending` lists those app ids for Omni Settings. It clears only values it wrote itself (`~/.local/state/omni-settings/steam-games-applied.json`).
- `localAi.{code,chat,edit}`: models from `local-models.nix` (folder, file match, model flags, and offload measured per GPU under `tuned.<profile>`) plus those the machine's `localModels.models` adds; the first coding model is the default. `local-ai.nix` gives each machine its models with final flags (profile defaults from `gpu-profiles.nix`, then `tuned.<profile>`, then `localModels.models.<id>`; no offload set means llama-server's own fit), read by `ai/llama-swap.nix` and `editors/zed.nix`. A machine's `gpuLayers = "auto"` drops the measured offload. `settings.nix` checks `localModels` and its tuning field list must match `local-ai.nix`'s, as must Omni Settings' `localmodelstate.effective`/`flags`, which mirror it for the Local Models page.

## Other files

- `mutable-merge.jq` — the merge that keeps GUI changes across rebuilds, shared by `wm/dms-mutable.nix`, `editors/zed.nix`, `file-browsers/dux-files.nix` and `ai/claude.nix`. Zed's template is `~/.config/zed/declarative-settings.json`, whose values the reset button on Omni Settings' Zed switch puts back into `settings.json`; theme and fonts are locked.
