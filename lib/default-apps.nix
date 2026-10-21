#=====================================================================#
# DEFAULT APPS
#=====================================================================#
#- The apps a user's defaultApps settings can pick from, and which one each
#- resolves to: the chosen app while its toggle is on, else the first of its
#- kind that is on, else the first listed. lib/settings.nix takes the
#- dropdown choices from `apps`; mime.nix and youtube-dispatch use `forUser`.
{lib}: let
  app = name: toggle: desktop: {inherit name toggle desktop;};
  #--- Browsers also carry the command youtube-dispatch hands non-YouTube links to
  browser = name: toggle: desktop: bin: app name toggle desktop // {inherit bin;};
in rec {
  apps = {
    browser = [
      (browser "zen" ["browsers" "zen"] "zen-beta.desktop" "zen-beta")
      (browser "mullvad" ["browsers" "mullvad"] "mullvad-browser.desktop" "mullvad-browser")
      (browser "helium" ["browsers" "helium"] "helium.desktop" "helium")
    ];
    textEditor = [
      (app "zed" ["editors" "zed"] "dev.zed.Zed.desktop")
      (app "helix" ["editors" "helix"] "Helix.desktop")
    ];
    terminal = [
      (app "kitty" ["terminals" "kitty"] "kitty.desktop")
      (app "ghostty" ["terminals" "ghostty"] "com.mitchellh.ghostty.desktop")
    ];
    fileManager = [
      (app "nautilus" ["fileBrowsers" "nautilus"] "org.gnome.Nautilus.desktop")
      (app "dolphin" ["fileBrowsers" "dolphin"] "org.kde.dolphin.desktop")
      (app "yazi" ["fileBrowsers" "yazi"] "yazi.desktop")
      (app "duxFiles" ["fileBrowsers" "duxFiles"] "dev.duxlabs.files.desktop")
    ];
  };

  forUser = user:
    lib.mapAttrs (kind: candidates: let
      on = lib.filter (c: lib.attrByPath c.toggle false user) candidates;
      chosen = lib.findFirst (c: c.name == user.defaultApps.${kind}) null on;
    in
      if chosen != null
      then chosen
      else if on != []
      then lib.head on
      else lib.head candidates)
    apps;
}
