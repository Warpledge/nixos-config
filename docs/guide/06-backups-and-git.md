# Backups and Git

## What the Config Covers

A reinstall brings back every app and setting the config holds, since the config *is* the system. What it doesn't hold is your data: documents, game saves, browser profiles, app libraries. Back those up separately.

## Backups

Main → **Backups** saves the app data that's hardest to rebuild by hand, for the apps you have on:

- **FreeTube**: subscriptions, playlists and history. Close FreeTube first.
- **Zen**: bookmarks, as a `bookmarks.html` any browser can import

**Back Up Everything** runs both. Each run goes in a dated folder under `~/SyncBackups`, which the folder button opens.

## Syncthing

Where Syncthing is on ([`syncthing.nix`](../../modules/nixos/services/servers/syncthing.nix)), it keeps folders the same across your devices. Its web page is at `http://localhost:8384`. It syncs whatever's in a folder, mistakes included, so it isn't a backup on its own.

## Git

The config is a git repository, a folder that records every change made to it. Main → **Git** shows:

- the branch, and files changed but not committed yet
- commits waiting to be pushed to GitHub, or pulled from it
- recent commits, and open pull requests

Its line in the page list says "In step" when everything is, or counts what's waiting. Changes Omni Settings makes stay uncommitted until an admin commits them, so the Git page is where to see what's been changed since. The exception is a backup: paste an empty repo you own (a private GitHub repo, say) into **Backup** on the Git page and **Back Up Here** pushes your copy there. From then on each successful Apply, Rebuild, Update or Pull commits what changed in this computer's `machines/` folder and your `users/` folder and pushes it, while updates keep coming from the repo you cloned. Git has to be able to push there without asking for a password, for example after `gh auth login` and `gh auth setup-git`, or with an SSH key. Under the hood it's a `backup` remote set as the branch's `pushRemote`.
