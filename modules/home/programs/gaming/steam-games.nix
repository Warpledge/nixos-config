#=====================================================================#
# STEAM GAMES (steamGames IN THE USER'S SETTINGS)
#=====================================================================#
#- Hands the setting to steam-games-apply (nixos/gaming/steam.nix), which
#- writes it into Steam's files now, or when Steam next starts if it's open.
{
  lib,
  pkgs,
  user,
  ...
}: {
  home.activation.steamGames = lib.hm.dag.entryAfter ["linkGeneration"] ''
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/omni-settings"
    run mkdir -p "$state"
    run install -m 644 ${pkgs.writeText "steam-games.json" (builtins.toJSON user.steamGames)} \
      "$state/steam-games.json"
    if [ -x /run/current-system/sw/bin/steam-games-apply ]; then
      run /run/current-system/sw/bin/steam-games-apply || true
    fi
  '';
}
