#=====================================================================#
# APPARMOR: MPV
#=====================================================================#
#- Also covers mpv started by ani-cli; under streamlink it inherits
#- streamlink's profile instead.
_: {
  security.apparmor.policies.mpv = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile mpv /nix/store/*-mpv-*/bin/{mpv,umpv} flags=(attach_disconnected) {
        include <abstractions/nix-desktop-app>
        include <abstractions/nix-fhs-env>
        include <abstractions/nix-mpv>
        include <abstractions/nix-network>

        # Media can sit anywhere outside the dotfiles
        owner @{HOME}/[^.]** r,
        /run/media/** r,
        /mnt/** r,

        # Screenshots default to the working directory
        owner @{HOME}/{,**/}mpv-shot* w,
      }
    '';
  };
}
