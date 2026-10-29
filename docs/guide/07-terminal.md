# The Terminal

Everything in Omni Settings can also be done from a terminal (`Mod+Return`). You don't need this to use the computer day to day.

## nixm

`nixm` (or just `n`) opens a menu you search by typing: NixOS, backups, Flatpak, firmware, network, monitoring, Android and Proton tools. Each item runs one command, which you can also type directly:

| Command | What it does |
| --- | --- |
| `nixm rebuild` | Rebuild and switch |
| `nixm boot` | Rebuild for the next restart |
| `nixm upgrade` | Update every source and rebuild |
| `nixm flake-update` | Update the sources without rebuilding |
| `nixm dryrun` | Build without switching, to see if it works |
| `nixm check-updates` | List newer upstream versions of pinned apps, and disabled packages that build again |
| `nixm rollback` | Pick an older generation and switch to it |
| `nixm gc` | Clean up, keeping the last five generations |
| `nixm backup` | Back up FreeTube and Zen |
| `nixm firmware-check` | Look for firmware updates |
| `nixm launch-params` | Pick a game launch option and copy it |

`nixm` with a word it doesn't know prints the full list. The menu is defined in [`nixm.nix`](../../modules/home/nixm.nix).

## Other Commands

- `run <package>` starts a package from nixpkgs once without installing it. It and the shell's other functions are in [`zsh.nix`](../../modules/home/programs/shell/zsh.nix).
- `Mod+Z` opens the config in your text editor. Edit [`users/<your name>/settings.nix`](../../users/{user}/settings.nix) there if you'd rather type than click; every setting has a comment saying what it does. Rebuild afterwards.
- `nix flake check` (in `/etc/nixos-config`) checks the config for mistakes without building it.
