#=====================================================================#
# FERDIUM CONFIGURATION
#=====================================================================#
{
  config,
  lib,
  pkgs,
  ...
}: let
  #--------------------------------------------------------------------#
  #-- Declared Services
  #--------------------------------------------------------------------#
  #--- `id` is the row the seed dedupes on. Keep it stable and never
  #--- reuse one: changing it orphans the service's cookies, which live
  #--- in a partition keyed by that id.
  services = [
    {
      id = "7c9785f8-3dba-44a0-ba8a-35241e15f774";
      name = "RateYourMusic";
      url = "https://www.rateyourmusic.com";
    }
  ];

  #--- Ferdium keeps the whole per-service config as one JSON blob and
  #--- reads fields straight off it, so every key it expects is spelled
  #--- out. A partial blob leaves settings toggles blank in the UI.
  settingsFor = s:
    builtins.toJSON {
      recipeId = "franz-custom-website";
      inherit (s) name;
      customUrl = s.url;
      isEnabled = true;
      isHibernationEnabled = false;
      isWakeUpEnabled = true;
      isNotificationEnabled = true;
      isBadgeEnabled = true;
      isMediaBadgeEnabled = false;
      isMuted = false;
      trapLinkClicks = false;
      # franz-custom-website ships no icon of its own, so pull the site's
      useFavicon = true;
      customIcon = null;
      isDarkModeEnabled = false;
      isProgressbarEnabled = false;
      spellcheckerLanguage = null;
      userAgentPref = null;
      proxy = {
        isEnabled = false;
        host = "";
        port = 0;
        user = "";
        password = "";
      };
      darkReaderSettings = {
        brightness = 100;
        contrast = 90;
        sepia = 10;
      };
    };

  sq = str: "'" + lib.replaceStrings ["'"] ["''"] str + "'";

  insertFor = s: ''
    INSERT INTO services (serviceId, name, recipeId, settings, created_at, updated_at)
    SELECT ${sq s.id}, ${sq s.name}, 'franz-custom-website', ${sq (settingsFor s)},
           datetime('now'), datetime('now')
    WHERE NOT EXISTS (SELECT 1 FROM services WHERE serviceId = ${sq s.id});
  '';

  seedSql =
    pkgs.writeText "ferdium-seed.sql"
    (lib.concatMapStrings insertFor services);
in {
  #--------------------------------------------------------------------#
  #-- Ferdium Package
  #--------------------------------------------------------------------#
  # The nixpkgs wrapper already adds the Wayland ozone flags when
  # NIXOS_OZONE_WL is set (home-manager/variables.nix).

  home.packages = with pkgs; [
    ferdium
  ];

  #--------------------------------------------------------------------#
  #-- Service Seed
  #--------------------------------------------------------------------#
  # Services are rows in server.sqlite, which Ferdium owns and rewrites from
  # the UI, so this is seed-only: each row is inserted once, never updated,
  # and in-app changes win. To re-seed one, delete it in the UI first, with
  # Ferdium closed - it writes the DB on exit.

  home.activation.ferdiumSeedServices = lib.hm.dag.entryAfter ["writeBoundary"] ''
    db="${config.xdg.configHome}/Ferdium/server.sqlite"
    if [[ ! -e "$db" ]]; then
      echo "ferdium: no server.sqlite yet, launch Ferdium once to let it migrate"
    elif ${pkgs.procps}/bin/pgrep -x ferdium >/dev/null; then
      echo "ferdium: running, skipping service seed"
    else
      run ${pkgs.sqlite}/bin/sqlite3 "$db" ".read ${seedSql}"
    fi
  '';
}
