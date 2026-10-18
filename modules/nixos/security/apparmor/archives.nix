#=====================================================================#
# APPARMOR: ARCHIVE TOOLS
#=====================================================================#
#- Keeps path-traversal archives out of the dotfiles (shell rc, autostart,
#- ~/.ssh). unzip and tar are left out: Nix builds run them too.
{
  lib,
  anyUser,
  ...
}: {
  security.apparmor.policies = {
    #--- File Roller, plus the 7z/bsdtar/unrar backends it runs
    file-roller = {
      state = "complain";
      profile = ''
        abi <abi/4.0>,
        include <tunables/global>

        profile file-roller /nix/store/*-file-roller-*/bin/{file-roller,.file-roller-wrapped} {
          include <abstractions/nix-desktop-app>

          owner @{HOME}/[^.]** rwlk,
          /run/media/** rwl,
          /mnt/** rwl,
          owner @{HOME}/.cache/file-roller{,/**} rwk,
          owner @{HOME}/.config/file-roller{,/**} rwk,
        }
      '';
    };

    #--- Ark, installed with Dolphin; its context-menu actions run `ark --batch`
    ark = lib.mkIf anyUser.fileBrowsers.dolphin {
      state = "complain";
      profile = ''
        abi <abi/4.0>,
        include <tunables/global>

        profile ark /nix/store/*-ark-*/bin/{ark,.ark-wrapped} {
          include <abstractions/nix-desktop-app>

          owner @{HOME}/[^.]** rwlk,
          /run/media/** rwl,
          /mnt/** rwl,
          owner @{HOME}/.config/arkrc* rwlk,
          owner @{HOME}/.local/state/arkstaterc* rwlk,
          owner @{HOME}/.local/share/{ark,kxmlgui5/ark}{,/**} rwk,
          owner @{HOME}/.cache/ark{,/**} rwk,
        }
      '';
    };

    #--- unrar from a terminal
    unrar = {
      state = "complain";
      profile = ''
        abi <abi/4.0>,
        include <tunables/global>

        profile unrar /nix/store/*-unrar-*/bin/unrar {
          include <abstractions/base>

          /nix/store/** mr,
          /etc/** r,
          owner /tmp/** rwk,
          owner @{HOME}/[^.]** rwlk,
          /run/media/** rwl,
          /mnt/** rwl,
        }
      '';
    };
  };
}
