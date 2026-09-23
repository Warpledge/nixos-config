#=====================================================================#
# APPARMOR: MANGAYOMI
#=====================================================================#
#- Runs third-party source extensions. Attaches to the binary inside the
#- AppImage, so the bubblewrap launcher around it stays unconfined.
_: {
  security.apparmor.policies.mangayomi = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile mangayomi /nix/store/*-mangayomi-*-extracted/usr/bin/mangayomi flags=(attach_disconnected) {
        include <abstractions/nix-desktop-app>
        include <abstractions/nix-fhs-env>
        include <abstractions/nix-network>

        owner @{HOME}/.local/share/{mangayomi,com.kodjodevf.mangayomi}{,/**} rwk,
        owner @{HOME}/.cache/com.kodjodevf.mangayomi{,/**} rwk,
        owner @{HOME}/Documents/Mangayomi{,/**} rwk,
      }
    '';
  };
}
