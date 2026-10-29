# Updates and Clean-Up

Nothing updates on its own. The config pins every source to an exact version (the sources are in [`flake.nix`](../../flake.nix), their versions in [`flake.lock`](../../flake.lock)), so the system stays the same until an admin updates it. All of this is on Main → **Maintenance**.

## Updating

1. **Check for Updates** lists each source (flake input) with a newer version, and when it last moved. nixpkgs is the big one: it carries almost every app.
2. Tick the sources to update. Leaving one out keeps it where it is, which helps when one update is known to break something.
3. **Update Now** moves them and rebuilds. **At Next Restart** waits for a restart, and **Preview** builds and shows what would change, then puts everything back.

The run page lists the packages that changed version. **What's New** on the Maintenance page links to each source's changes on GitHub.

Some updates switch at the next restart even if you picked Update Now: a new systemd, glibc, niri or xwayland-satellite has frozen the desktop when switched live. The Maintenance page then shows **Restart to finish**. A new kernel also needs a restart to start using it.

Updating every week or two keeps each jump small, which makes problems easier to find.

When the config's own repository has new commits (the Git page counts them as "to pull"), a **Config** row above the sources offers **Pull**. It runs `git pull --rebase`, so commits you made yourself stay on top, or a merge instead when your branch already has a merge commit (a fork that merges upstream), then rebuilds the same way Update Now does. If you'd also updated flake.lock without committing it and the new commits change it too, theirs wins. Where the branch pushes somewhere other than where it pulls from (`branch.<name>.pushRemote`), your commits are pushed there once the rebuild succeeds ([Backups and Git](06-backups-and-git.md)).

## Versions

Every rebuild keeps the previous generation. The **Versions** list shows them, marked **Running**, **Next start** or **Started with**.

- The compare button shows what's different from the running version.
- **Switch** goes back to that version (admins only). It changes the running system, not your settings files, so your next Apply builds from the files again.

The boot menu keeps the last ten by default, set on Omni Settings' **Boot** page ([`bootloader.nix`](../../modules/nixos/system/bootloader.nix)). If a version won't start, restart and pick an older one there.

## Clean-Up

Old generations and their packages take disk space. **Clean Up Old Versions** deletes the old ones, keeping the newest five plus any made in the last five days, then removes the files nothing uses any more. The dialog estimates how much it frees. Deleted versions leave the boot menu and you can't switch back to them.

The same clean-up runs on its own every week ([`nh.nix`](../../modules/nixos/nix/nh.nix) sets what it keeps), so you only need the button when space is short.

## Rebuild Now

**Rebuild Now** rebuilds from the files as they are, with no new changes. Use it after editing the config by hand, or to retry a rebuild that failed for a reason outside the config (like a network drop).
