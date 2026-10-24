# Port Omni Settings to QML

**Goal:** replace Omni Settings' GTK4/libadwaita front end with QML in DMS's style, so the same UI runs as a DMS slideout panel (opened from anywhere, hidden mid-rebuild) and as a full window. Decided 2026-10-23 after a throwaway prototype of the Overview page.

Added 2026-10-23.

## What's already in the repo

- `modules/home/programs/system/omni-settings/src/`: about 9,700 lines of Python (2026-10-23). About 3,700 of them are already GTK-free and stay as the backend: `helper.py`, `schema.py`, `backend.py`, `system.py`, `nixfile.py`, `nixlog.py`, `dms.py`, `closure.py`, `session.py`. The rest (`app.py`, `windowrules.py`, `runview.py`, `flatpaks.py`, `packages.py`, `overview.py` and smaller pages) mixes logic with GTK calls.
- DMS 2.0.0 (2026-10-20 build) has the parts a panel needs: `Widgets/DSlideout.qml` (`slideEdge`, `expandable`, `hoverDismissEnabled` with a grace delay, content built on first `show()` and kept loaded) and plugins of type `widget`/`daemon`, loaded here through `dms-plugin-registry` in `modules/wm/niri/home/dms/default.nix`.
- The prototype read `system.info()` through a 40-line JSON script in about 50 ms and drew the Overview in Quickshell with colours from `~/.cache/DankMaterialShell/dms-colors.json`. It wasn't kept in the repo.

## Layout

- DMS's settings look: each row its own rounded block with a circular icon badge, sections headed in the primary colour, pill buttons.
- Top tabs (Main, Packages, Niri, AI, Docs) as a segmented row under the header.
- The sidebar becomes a current-page card that opens into the grouped page list with a search field, since a 480 px panel has no room for a sidebar.

## Steps

1. Backend JSON layer over the GTK-free modules; move the logic out of the GTK page files into it page by page.
2. Run the backend as a systemd user service that owns rebuild, clean-up and update jobs, so hiding the panel or restarting DMS (a rebuild that updates DMS restarts it) doesn't end a job. Clients reattach to a running job's progress and log.
3. Notification when a job finishes or fails, silent while the panel is hidden (quick-todos item 19); `runview.py`'s `notify_done` moves into the service.
4. QML shell and shared widgets, then the generated settings pages from `schema.py`, then the custom pages. Work on a branch with the QML front end beside the GTK one (`omni-settings --qml`) until it matches.
5. DMS plugin: the panel as a `DSlideout` on the right edge, toggled by a niri keybind and a hot corner (a small transparent layer-shell trigger, since niri's `hot-corners` only toggles the overview), closing when the cursor leaves through `hoverDismissEnabled`, suspended while a field has focus.
6. The standalone window must work without DMS (other WMs, the `stranger` check), themed through qt6ct and matugen.
7. Drop GTK, then update Omni Settings' `CLAUDE.md`, `AGENTS.md`, README and the `docs/guide/` pages.

## Gotchas

- **Root session:** `session.py` keeps the pkexec helper for 15 minutes idle on a socket pair only the window holds. A service needs a socket on disk, and any process running as the user could then use an unlocked root session. End the root session when each job ends instead (one password per job).
- **Hot corner:** `modules/wm/niri/home/core/settings.nix` sets `gestures = {hot-corners.enable = true;};`, niri's top-left overview corner. Set it to `false` before giving that corner to the panel.
- **Usage:** the Overview prototype alone was cheap, but the full port is days of sessions. Start it at the start of a usage week, one page per session, with `/clear` between pages.
