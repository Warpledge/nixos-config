#=====================================================================#
# APPARMOR: EVINCE
#=====================================================================#
#- No network rules: a hostile PDF can read documents but not send them out.
_: {
  security.apparmor.policies.evince = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile evince /nix/store/*-evince-*/bin/{evince,evince-previewer,.evince-wrapped,.evince-previewer-wrapped} {
        include <abstractions/nix-desktop-app>
        include <abstractions/cups-client>

        # Open, annotate and save copies anywhere outside the dotfiles
        owner @{HOME}/[^.]** rwk,
        /run/media/** rw,
        /mnt/** rw,
        owner @{HOME}/.config/evince{,/**} rwk,
        owner @{HOME}/.local/share/evince{,/**} rwk,
      }
    '';
  };
}
