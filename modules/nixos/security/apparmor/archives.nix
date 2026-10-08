#=====================================================================#
# APPARMOR: ARCHIVE TOOLS
#=====================================================================#
#- Keeps path-traversal archives out of the dotfiles (shell rc, autostart,
#- ~/.ssh). unzip and tar are left out: Nix builds run them too.
_: {
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
