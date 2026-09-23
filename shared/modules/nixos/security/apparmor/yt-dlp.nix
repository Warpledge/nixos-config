#=====================================================================#
# APPARMOR: YT-DLP
#=====================================================================#
#- Only when run directly; started by mpv it inherits mpv's profile.
_: {
  security.apparmor.policies.yt-dlp = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile yt-dlp /nix/store/*-yt-dlp-*/bin/{yt-dlp,.yt-dlp-wrapped} {
        include <abstractions/base>
        include <abstractions/nameservice>
        include <abstractions/ssl_certs>
        include <abstractions/nix-network>

        # Python, ffmpeg and the JS runtime for YouTube challenges
        /nix/store/** mrix,
        /etc/** r,
        /sys/** r,
        /dev/tty rw, # Progress output
        @{PROC}/sys/** r,
        owner @{PROC}/@{pid}/** r,
        owner /tmp/** rwk,

        # Downloads land in the working directory
        owner @{HOME}/[^.]** rwk,
        /run/media/** rw,
        /mnt/** rw,
        owner @{HOME}/.cache/yt-dlp{,/**} rwk,
        owner @{HOME}/.config/yt-dlp/** r,

        signal (send, receive) peer=@{profile_name},
      }
    '';
  };
}
