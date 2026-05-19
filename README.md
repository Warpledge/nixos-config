# Warpledge's NixOS Configuration

My personal NixOS system flake.

## Host Machines

- **Desktop** — Ryzen 5800X3D + RX 9070 XT (AMD-only), 280Hz OLED + 144Hz secondary
- **Laptop** — Legion Slim 5, Ryzen 7735HS + hybrid AMD 680M / RTX 4070, 1600p@165Hz

## Screenshots

<details>
<summary>Niri WM</summary>

![Niri desktop with Zed and fastfetch](./screenshots/niri-desktop.png)

</details>

<details>
<summary>Hyprland WM</summary>

![Hyprland desktop with Zed and fastfetch](./screenshots/Hyprland-Desktop.png)

</details>



## Components

Most components below are toggleable per host via `hostConfig` and rebuilding. "Active" marks the one currently selected on my machines; the others are wired up and selectable.

|                                                | NixOS (Wayland)                                                                                                                  |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Window Manager**                             | [Niri][niri] (active) / [Hyprland][hyprland]                                                                                     |
| **Status Bar / Notifier / Launcher / Lock**    | [DankMaterialShell][dms] (Niri + Hyprland)                                                                                       |
| **Display Manager**                            | [tuigreet][tuigreet] via [greetd][greetd]                                                                                        |
| **Color Scheme**                               | [Catppuccin][catppuccin] Mocha Mauve applied globally via [Stylix][stylix] + [catppuccin/nix][catppuccin-nix]                    |
| **Fonts**                                      | [JetBrains Mono Nerd Font][nerd-fonts], Monaspace, Nerd Fonts Symbols                                                            |
| **Shell**                                      | [Zsh][zsh] + [Powerlevel10k][p10k] / [Starship][starship], with [atuin][atuin], [fzf][fzf], [zoxide][zoxide], [eza][eza]         |
| **Terminal Emulator**                          | [Kitty][kitty] (active) / [Ghostty][ghostty]                                                                                     |
| **Multiplexer**                                | [tmux][tmux]                                                                                                                     |
| **Editors / IDE**                              | [Zed][zed] (active), [Helix][helix], [micro][micro] (quick edits)                                                                |
| **Browsers**                                   | [Zen][zen] / [Mullvad Browser][mullvad-browser] / [Helium][helium]                                                               |
| **File Manager**                               | [Nautilus][nautilus]                                                                                                             |
| **Media Player**                               | [mpv][mpv], [Spotify][spotify] via [spicetify-nix][spicetify], [Grayjay][grayjay]                                                |
| **Screenshot / Recording**                     | [grim][grim] + [slurp][slurp], [gpu-screen-recorder][gpu-screen-recorder]                                                        |
| **Creative**                                   | [Blender][blender], [Krita][krita]                                                                                               |
| **Chat / Productivity**                        | [Discord][discord] via [nixcord][nixcord], [Thunderbird][thunderbird], [Obsidian][obsidian]                                      |
| **Gaming**                                     | [Steam][steam] (Gamescope session), [GameMode][gamemode], [MangoHud][mangohud], [Goverlay][goverlay], [r2modman][r2modman]       |
| **AI Tooling**                                 | [Claude Code][claude-code], [OpenCode][opencode], [LM Studio][lmstudio]                                                          |
| **Containers / VMs**                           | [Docker][docker], [Waydroid][waydroid] (Android), [WinBoat][winboat] (Windows apps)                                              |
| **Networking**                                 | [Mullvad][mullvad] (WireGuard + quantum resistance), [systemd-resolved][resolved] + [NetworkManager][networkmanager] (iwd)       |
| **Game Streaming**                             | [Sunshine][sunshine]                                                                                                             |
| **Antivirus**                                  | [ClamAV][clamav] (toggleable)                                                                                                    |
| **Keymap Daemon**                              | [keyd][keyd]                                                                                                                     |
| **Secrets / Keyring**                          | [GNOME Keyring][gnome-keyring]                                                                                                   |
| **Filesystem & Encryption**                    | ext4 on a [LUKS][luks]-encrypted partition, unlocked at boot                                                                     |
| **Bootloader**                                 | [systemd-boot][systemd-boot]                                                                                                     |
| **Kernel**                                     | [CachyOS kernel][cachyos-kernel] (selectable: zen / latest / xanmod / cachyos)                                                   |
| **Formatter**                                  | [alejandra][alejandra] v3.0.0                                                                                                    |
| **Rebuild Wrapper**                            | [`nixy`](./shared/modules/home-manager/scripts/nixy.nix) (fzf menu over [nh][nh])                                                |

[niri]: https://github.com/YaLTeR/niri
[hyprland]: https://hyprland.org
[dms]: https://github.com/AvengeMedia/DankMaterialShell
[tuigreet]: https://github.com/apognu/tuigreet
[greetd]: https://git.sr.ht/~kennylevinsen/greetd
[catppuccin]: https://github.com/catppuccin/catppuccin
[catppuccin-nix]: https://github.com/catppuccin/nix
[stylix]: https://github.com/nix-community/stylix
[nerd-fonts]: https://www.nerdfonts.com
[zsh]: https://www.zsh.org
[p10k]: https://github.com/romkatv/powerlevel10k
[starship]: https://starship.rs
[atuin]: https://atuin.sh
[fzf]: https://github.com/junegunn/fzf
[zoxide]: https://github.com/ajeetdsouza/zoxide
[eza]: https://github.com/eza-community/eza
[kitty]: https://sw.kovidgoyal.net/kitty
[ghostty]: https://ghostty.org
[tmux]: https://github.com/tmux/tmux
[zed]: https://zed.dev
[helix]: https://helix-editor.com
[micro]: https://micro-editor.github.io
[zen]: https://zen-browser.app
[mullvad-browser]: https://mullvad.net/en/browser
[helium]: https://github.com/schembriaiden/helium-browser-nix-flake
[nautilus]: https://apps.gnome.org/Nautilus
[mpv]: https://mpv.io
[spotify]: https://www.spotify.com
[spicetify]: https://github.com/Gerg-L/spicetify-nix
[grayjay]: https://grayjay.app
[grim]: https://sr.ht/~emersion/grim
[slurp]: https://github.com/emersion/slurp
[gpu-screen-recorder]: https://git.dec05eba.com/gpu-screen-recorder
[blender]: https://www.blender.org
[krita]: https://krita.org
[discord]: https://discord.com
[nixcord]: https://github.com/KaylorBen/nixcord
[thunderbird]: https://www.thunderbird.net
[obsidian]: https://obsidian.md
[steam]: https://store.steampowered.com
[gamemode]: https://github.com/FeralInteractive/gamemode
[mangohud]: https://github.com/flightlessmango/MangoHud
[goverlay]: https://github.com/benjamimgois/goverlay
[r2modman]: https://github.com/ebkr/r2modmanPlus
[claude-code]: https://github.com/anthropics/claude-code
[opencode]: https://github.com/opencode-ai/opencode
[lmstudio]: https://lmstudio.ai
[docker]: https://www.docker.com
[waydroid]: https://waydro.id
[winboat]: https://github.com/TibixDev/winboat
[mullvad]: https://mullvad.net
[resolved]: https://www.freedesktop.org/software/systemd/man/systemd-resolved.html
[networkmanager]: https://networkmanager.dev
[sunshine]: https://github.com/LizardByte/Sunshine
[clamav]: https://www.clamav.net
[keyd]: https://github.com/rvaiya/keyd
[gnome-keyring]: https://wiki.gnome.org/Projects/GnomeKeyring
[luks]: https://gitlab.com/cryptsetup/cryptsetup
[systemd-boot]: https://www.freedesktop.org/software/systemd/man/systemd-boot.html
[cachyos-kernel]: https://github.com/CachyOS/linux-cachyos
[alejandra]: https://github.com/kamadorueda/alejandra
[nh]: https://github.com/nix-community/nh

## How it's wired up

```
flake.nix
  → hosts/{hostname}/{hostname}.nix             (host entry)
    → hosts/{hostname}/hostConfig/core.nix      (per-host toggles, passed as specialArgs)
    → shared/core.nix                           (NixOS + home-manager integration)
      → shared/modules/{nixos,home-manager}/    (modular configs, conditional imports)
      → shared/modules/wm/${windowManager}/     (active WM only)
```

Each host has a `hostConfig/core.nix` that controls window manager, kernel, browsers, terminals, editors, VPN, Docker, Waydroid, AI tools, and more from one place. Module `default.nix` files use `lib.optionals hostConfig.<option>` to decide what loads — so flipping a single boolean is the whole "enable/disable" workflow.

## Structure

```
flake.nix
hosts/{desktop,laptop}/
  ├── hostConfig/core.nix    # per-host toggles
  ├── {hostname}.nix         # host entry
  ├── hardware-configuration.nix
  ├── gpu.nix                # per-host GPU configuration
  └── wm/                    # per-host WM overrides
shared/
  ├── core.nix               # NixOS + home-manager wiring
  └── modules/
      ├── nixos/             # system modules
      ├── home-manager/      # user modules
      ├── theme/             # stylix, catppuccin, fonts, GTK, QT
      └── wm/                # window managers
.notes/                      # personal notes I share between devices
```

## History

I've been on NixOS since 2023. Most of what I know I learned by trial and error and referencing other public NixOS config repos, YouTube guides, and hands-on experimentation.

This is iteration 9 of remaking the entire NixOS config from scratch, improving on previous iterations, fixing mistakes, and refining everything to my personal preferences.

## Inspiration

These are the biggest inspirations for my own config and learning NixOS.

- [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) - has a very useful guide I've referenced many times
- [linuxmobile/shin](https://github.com/linuxmobile/shin) - inspired my switch to Niri WM
- [anotherhadi/nixy](https://github.com/anotherhadi/nixy) - inspiration for the nixy system management TUI script
- [Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config) - biggest inspiration to get into NixOS overall
