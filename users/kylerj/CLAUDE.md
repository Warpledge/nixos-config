# kylerj

Ky, admin, logs in on `activenixtab` only. Uses it for gaming (Steam, Heroic, emulators
through RetroDECK and RetroShelf), creative work, coding and local AI. Moved from KDE
Plasma, so the niri binds follow Plasma's shortcuts.

- **Updates never go through a terminal.** Ky updates from Omni Settings (Overview,
  Config, Pull), which rebases onto Warpledge's main, pushes to the backup and
  rebuilds. Don't hand back terminal steps for updating, and don't add a background
  auto-pull or auto-rebuild.
- **Ky's changes stay in `machines/activenixtab/` and `users/kylerj/`.** Never edit
  Warpledge's shared files for Ky's setup. A fix others could use goes upstream as a
  pull request (the `upstream` skill), opened ready for review, not as a draft, and only
  after Ky approves it.
- **The goal is a config anyone can install and keep up to date without an AI.** Prefer
  a general fix in `setup.sh`, Omni Settings or the docs over hand-configured git.
- Apps with no settings switch are in `machines/activenixtab/home/apps.nix`; the browser
  is Vivaldi, though `defaultApps.browser` says zen.
- Only two app keys matter: Meta+T for the terminal and Ctrl+Alt+Delete for the task
  manager. Everything else opens from the launcher.
- RetroShelf (`votex09/retroshelf`) is Ky's own app, packaged as a flake input that
  tracks its main.
- Per-app niri window rules go in Omni Settings' Window Rules page.
- Theming stays the same across GTK and Qt/KDE apps (Kvantum, Papirus-Dark).
- Ky has no other Nix machine, so a change can't be tried anywhere first.
