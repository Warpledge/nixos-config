# Home modules

<!-- Claude Code loads this file when it reads a file in this folder. -->

## Layout

- `programs/<category>/` holds the apps; `options.nix`, `utilities.nix` (the general package list) and `user-packages.nix` (a user's `userPackages`, added from Omni Settings' Packages tab) sit at the root. `mime.nix`, `nixm.nix`, `services.nix`, `update-reminder.nix` (admins only: a daily timer that notifies once `flake.lock`'s nixpkgs is the machine's `maintenance.updateReminderDays` old) and `variables.nix` are single files at that level, not directories.
- Wrappers for prebuilt bundles in `~/.local/opt/` (`media/tonkatsu-box.nix`, `gaming/tools/relink-mod-organizer.nix`, `audio/guitar/katana-floorboard.nix`) and AppImage wraps (`appimageTools`, hash-pinned into the store) both sit in the folder for what the app is, not how it is packaged (`docs/personal/local/{local-binary-installs,appimage-wraps}.md`). `gaming/tools/reloaded-ii-gbfr.nix` is the exception: a Windows `.exe` its installer puts in `~/Desktop/Reloaded-II - Granblue Fantasy Relink/`, run in GBFR's Proton prefix through `protontricks-launch`.
- `~/.local/opt` bundles (kept out of git) have no category of their own: `media.tonkatsuBox`, `gaming.granblueRelinkMods` and `audio.katanaFloorboard` wrap them; see `docs/personal/local/local-binary-installs.md`. `setup.sh` doesn't offer them.
- `programs/ai/` — Claude Code, opencode, Pi and the shared MCP servers (`mcp.nix`; API keys are read at launch from owner-only files in `~/.nixos-config-mcp/`, never the repo or the store). Skills and subagents live in `skills/<name>/` and `agents/<name>.md`, registered in `claude.nix`; new ones (including what skill-creator writes to `~/.claude/skills/`) move here. Its `CLAUDE.md` has the rest.
- `default.nix` carries a `clearStaleBackups` activation hook that deletes `*.bak` under `~/.config`, `~/.local/{share,state}` before `checkLinkTargets`. This is why HM activation never fails on leftover backups. Don't remove it when debugging a "file exists" error; find the real conflicting file instead.

## Gotchas

- Home routers (`home/default.nix`, `programs/default.nix`, `programs/gaming/default.nix`, `audio/guitar/default.nix`) read `user` in `imports`, where `_module.args` can't reach, so they take it as a plain first argument (`user: {lib, ...}: {...}`) and their parent imports them with `(import ./gaming user)`.
- Don't switch the home routers to `lib.modules.importApply`. Its extra nesting reorders the home modules, and options whose type keeps the last definition flip: FreeTube's `secColor` went from the repo's Lavender to catppuccin/nix's Mauve when this was tried on 2026-10-17. The routers set `_file` so errors still name them.
- `gaming.steam` is wired in `modules/nixos/gaming/default.nix`; the rest of `gaming.*` is wired in `programs/gaming/default.nix`.
- `audio/guitar/` loads when any of `audio.{guitarix,tone3000,katanaFloorboard}` is on; its `default.nix` holds the shared cab IR, tuner and patchbay packages plus the plugin paths, then gates each app on its own toggle.
- `ai/{claude,opencode,lmstudio}.nix` are conditionally imported **and** wrap their body in `config = lib.mkIf user.<toggle> {...}`, so the inner guard never fires on its own. New modules take the conditional import alone.
- **Moku is built from source, pinned twice:** the `moku` and `tsunagu` inputs move together; the `moku-bump` skill has the bump order and the patches. Sources that drive an Android WebView can't work in Tsunagu.
