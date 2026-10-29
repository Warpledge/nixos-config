# Start Here

NixOS builds the whole computer from a set of text files. Apps, services, settings and the desktop are all written down in one folder, and nothing changes until you rebuild from it. If a change goes wrong you can go back to the version from before, because each rebuild is kept.

On this setup you don't have to edit those files yourself. Omni Settings (`Mod+S`) shows them as switches, lists and dropdowns, and does the rebuild for you.

## The Words You'll See

| Word | What it means here |
| --- | --- |
| Config | The folder [`/etc/nixos-config`](../../), which describes this computer and every other one it runs on |
| Rebuild | Building a new system from the config and switching to it. Every change goes through one |
| Generation (version) | One finished rebuild. The Maintenance page lists them as Version 1, 2, 3… |
| Switch | Moving the running system to a new generation without restarting |
| At next restart | Building now, but starting the new generation only when you restart (`nixos-rebuild boot`) |
| Flake input (source) | Something the config is built from, like nixpkgs, the big collection of packages. Updating means moving these to newer versions |
| Garbage collection (clean-up) | Deleting old generations and the files only they used, to free disk space |
| Home-manager | The part that sets up your own apps and their settings in your home folder |

## What's Yours and What's Shared

There are two kinds of settings, and Omni Settings keeps them apart:

- **Your settings** are the apps you have, your default apps and your account. They live in [`users/<your name>/settings.nix`](../../users/{user}/settings.nix) and only affect you.
- **Computer settings** are the kernel, services, firewall, language and the like. They live in [`machines/<computer>/settings.nix`](../../machines/{machine}/settings.nix) and apply to everyone who logs in.

Every setting either file can hold is listed, with a comment saying what it does, in the templates: [`users/_template/settings.nix`](../../users/_template/settings.nix) and [`machines/_template/settings.nix`](../../machines/_template/settings.nix). Links like these open the file in your text editor.

Admins can change both. Everyone else can change their own settings, and sees the computer ones locked. An admin is someone with **Admin** on in Users, which also lets them use `sudo`.

## The One Rule

Make changes through Omni Settings or the config, then rebuild. Most app settings under `~/.config` are written by the rebuild, so a change made there by hand can be replaced or refused the next time. Settings that apps change from their own menus (DMS, Zed, Dux Files, FreeTube) are the exception: those are kept across rebuilds.

## Where to Go Next

- [Changing Settings](02-changing-settings.md): how Omni Settings works
- [Installing Apps](03-installing-apps.md): adding and removing software
- [Updates and Clean-Up](04-updates-and-cleanup.md): keeping the system current and going back a version
- [Using the Desktop](05-desktop.md): windows, workspaces and shortcuts
- [Backups and Git](06-backups-and-git.md): saving your data and seeing what changed in the config
- [The Terminal](07-terminal.md): the same jobs from a terminal
- [When Things Go Wrong](08-when-things-go-wrong.md): what to do when a rebuild fails or something breaks
- [The Side Rail](09-side-rail.md): the `Mod+A` rail of apps docked on the left, its terminal and its tabs
