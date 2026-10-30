#=====================================================================#
# APPARMOR: KATANA FXFLOORBOARD
#=====================================================================#
#- Prebuilt Qt bundle in ~/.local/opt, run through nix-ld. Reaches the amp
#- over the ALSA sequencer, which abstractions/audio already allows.
{apparmorState, ...}: {
  security.apparmor.policies.katana-floorboard = {
    state = apparmorState "katana-floorboard";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile katana-floorboard @{HOME}/.local/opt/katana-fxfloorboard/Katana-MK2-FxFloorBoard {
        include <abstractions/nix-desktop-app>

        owner @{HOME}/.local/opt/katana-fxfloorboard/** mr,
        # The wrapper cd's into the bundle, and these land in the working directory
        owner @{HOME}/.local/opt/katana-fxfloorboard/{assign.kat,license.txt,preferences.xml} rw,

        # Patches opened and saved anywhere outside the dotfiles
        owner @{HOME}/[^.]** rwk,
      }
    '';
  };
}
