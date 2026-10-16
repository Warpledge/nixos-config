#=====================================================================#
# APPARMOR: TONKATSU BOX
#=====================================================================#
#- Prebuilt Flutter bundle in ~/.local/opt, built and reviewed by nobody
#- here. Starts from what a desktop app needs; the log shows the rest.
_: {
  security.apparmor.policies.tonkatsu-box = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile tonkatsu-box @{HOME}/.local/opt/tonkatsu-box/tonkatsu_box {
        include <abstractions/nix-desktop-app>
        include <abstractions/nix-network>

        owner @{HOME}/.local/opt/tonkatsu-box/** mr,
      }
    '';
  };
}
