#=====================================================================#
# APPARMOR: PRISM LAUNCHER
#=====================================================================#
#- Mods are arbitrary Java code; this keeps them out of browser profiles,
#- Discord tokens and ~/.ssh. Attaches to the real binary, so the
#- mullvad-exclude wrapper in front of it stays unconfined.
_: {
  security.apparmor.policies.prismlauncher = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile prismlauncher /nix/store/*-prismlauncher-*/bin/prismlauncher flags=(attach_disconnected) {
        include <abstractions/nix-desktop-app>
        include <abstractions/nix-network>

        # Instances, mods, downloaded Java runtimes and extracted natives
        owner @{HOME}/.local/share/PrismLauncher{,/**} rwlkmix,
        owner /tmp/** m,
        owner @{HOME}/.java{,/**} rwk,
        owner @{HOME}/.cache/JNA{,/**} rwkm,
        owner @{HOME}/.cache/resourcefullib{,/**} rwk,
        owner @{HOME}/.jdks{,/**} r, # Scanned for Java installs

        # JVM and system-info probes
        /dev/tty rw,
        /dev/ r,
        owner @{PROC}/@{pid}/coredump_filter w,
        @{PROC}/@{pid}/net/{dev,if_inet6} r,
        @{PROC}/{cgroups,cmdline,devices,version} r,
        @{PROC}/scsi/ r,

        # Modpack and mod imports
        owner @{HOME}/Downloads{,/**} r,

        # Controllers
        /dev/input/ r,
        /dev/input/* r,
        /run/udev/data/** r,
      }
    '';
  };
}
