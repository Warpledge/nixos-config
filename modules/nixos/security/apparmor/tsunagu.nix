#=====================================================================#
# APPARMOR: TSUNAGU
#=====================================================================#
#- Moku's backend runs source extensions from third-party repos in its
#- sandbox JVM, which has no OS-level confinement of its own. Attaches to
#- the Go server; the JVM and ffmpeg it starts inherit the profile.
{apparmorState, ...}: {
  security.apparmor.policies.tsunagu = {
    state = apparmorState "tsunagu";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile tsunagu /nix/store/*-tsunagu-server-*/bin/tsunagu {
        include <abstractions/base>
        include <abstractions/nameservice>
        include <abstractions/ssl_certs>
        include <abstractions/nix-network>

        # The server, the JRE running extensions, and ffmpeg for streams
        /nix/store/** mrix,
        /etc/** r,
        /sys/** r,
        @{PROC}/sys/** r,
        @{PROC}/{cpuinfo,meminfo,stat} r,
        owner @{PROC}/@{pid}/** r,
        owner /tmp/** rwk,
        owner /dev/shm/** rwk,

        # Library, settings and installed extensions
        owner @{HOME}/.local/share/tsunagu{,/**} rwk,

        signal (send, receive) peer=@{profile_name},
        signal (receive) peer=unconfined, # Moku stopping it
      }
    '';
  };
}
