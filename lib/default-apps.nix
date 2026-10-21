#=====================================================================#
# DEFAULT APPS
#=====================================================================#
#- The apps a user's defaultApps settings can pick from, and which one each
#- resolves to: the chosen app while its toggle is on, else the first of its
#- kind that is on, else the first listed. lib/settings.nix takes the
#- dropdown choices from `apps`; mime.nix, youtube-dispatch and the WM binds
#- use `forUser`.
{lib}: let
  #--- `launch` is the command the WM binds spawn, as an argument list
  app = name: toggle: desktop: launch: {inherit name toggle desktop launch;};
  #--- Browsers also carry the command youtube-dispatch hands non-YouTube links to
  browser = name: toggle: desktop: bin: app name toggle desktop [bin] // {inherit bin;};
in rec {
  apps = {
    browser = [
      (browser "zen" ["browsers" "zen"] "zen-beta.desktop" "zen-beta")
      (browser "mullvad" ["browsers" "mullvad"] "mullvad-browser.desktop" "mullvad-browser")
      (browser "helium" ["browsers" "helium"] "helium.desktop" "helium")
    ];
    textEditor = [
      (app "zed" ["editors" "zed"] "dev.zed.Zed.desktop" ["zeditor"])
      (app "helix" ["editors" "helix"] "Helix.desktop" ["xdg-terminal-exec" "hx"])
    ];
    terminal = [
      (app "kitty" ["terminals" "kitty"] "kitty.desktop" ["kitty"])
      (app "ghostty" ["terminals" "ghostty"] "com.mitchellh.ghostty.desktop" ["ghostty"])
    ];
    fileManager = [
      (app "nautilus" ["fileBrowsers" "nautilus"] "org.gnome.Nautilus.desktop" ["nautilus"])
      (app "dolphin" ["fileBrowsers" "dolphin"] "org.kde.dolphin.desktop" ["dolphin"])
      (app "yazi" ["fileBrowsers" "yazi"] "yazi.desktop" ["xdg-terminal-exec" "yazi"])
      (app "duxFiles" ["fileBrowsers" "duxFiles"] "dev.duxlabs.files.desktop" ["dfiles"])
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
