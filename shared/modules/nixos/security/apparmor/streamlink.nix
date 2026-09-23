#=====================================================================#
# APPARMOR: STREAMLINK
#=====================================================================#
#- Runs inside the Streamlink Twitch GUI's bubblewrap sandbox, and the
#- mpv it pipes into inherits this profile, so it carries mpv's rules.
_: {
  security.apparmor.policies.streamlink = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile streamlink /nix/store/*-streamlink-*/bin/{streamlink,.streamlink-wrapped} flags=(attach_disconnected) {
        include <abstractions/nix-desktop-app>
        include <abstractions/nix-fhs-env>
        include <abstractions/nix-mpv>
        include <abstractions/nix-network>

        owner @{HOME}/.config/streamlink/** r,
        owner @{HOME}/.local/share/streamlink{,/**} rwk,
        owner @{HOME}/.cache/streamlink{,/**} rwk,
      }
    '';
  };
}
