#=====================================================================#
# SIDE RAIL APPS WITH THE USER'S CHANGES
#=====================================================================#
# The Mod+A rail's shared apps, each kept only when its app is on, with the
# user's sideRail setting (Omni Settings' Side Rail page): an app turned off,
# reordered or given a width by id, then the user's own custom- apps.
{
  lib,
  user,
  machine,
}: let
  #-- Geometry, in logical pixels; rules.nix and SideRail.qml both read these
  geometry = {
    rail = 52; # The icon rail's width
    gap = 8; # Between the rail and the app, and above and below the app
    width = 1260; # About 120 kitty columns, the old terminal panel's width
    presets = {
      Narrow = 640;
      Wide = 1600;
    };
  };

  #--- Helium names an --app window's app-id after the URL, port dropped:
  #--- https://search.brave.com/ask -> chrome-search.brave.com__ask-Default
  heliumAppId = url: let
    rest = lib.last (lib.splitString "://" url);
    parts = lib.splitString "/" rest;
    host = lib.head (lib.splitString ":" (lib.head parts));
    path = lib.concatStringsSep "_" (lib.tail parts);
  in "chrome-${host}__${path}-Default";

  web = id: name: icon: url: {
    inherit id name icon url;
  };

  shared =
    lib.optional user.terminals.kitty {
      id = "terminal";
      name = "Terminal";
      icon = "kitty";
      appId = "side-rail-terminal";
      command = ["kitty" "--class" "side-rail-terminal" "--directory" machine.flakePath];
    }
    ++ lib.optional user.browsers.helium
    (web "brave-ai" "Ask Brave" "travel_explore" "https://search.brave.com/ask")
    ++ lib.optional user.claudeDesktop.enable {
      id = "claude-desktop";
      name = "Claude Desktop";
      icon = "claude-desktop";
      appId = "com.anthropic.Claude";
      command = ["claude-desktop"];
    }
    ++ lib.optional user.opencodeDesktop.enable {
      id = "opencode-desktop";
      name = "OpenCode Desktop";
      icon = "opencode-desktop";
      appId = "ai.opencode.desktop";
      command = ["opencode-desktop"];
    }
    ++ lib.optional (user.browsers.helium && user.llamaSwap.enable)
    (web "llama-swap" "llama-swap" "memory" "http://127.0.0.1:8090/ui")
    ++ lib.optional (user.browsers.helium && user.openWebui.enable)
    (web "open-webui" "Open WebUI" "forum" "http://127.0.0.1:8091");

  changes = user.sideRail;
  on = e: e.enable or true;

  #--- Shared apps keep their place unless given an order; custom ones follow
  kept = lib.imap0 (i: e: let
    change = changes.${e.id} or {};
  in
    e // {order = change.order or i;} // lib.optionalAttrs (change ? width) {inherit (change) width;})
  (lib.filter (e: on (changes.${e.id} or {})) shared);
  custom = lib.mapAttrsToList (id: e:
    {
      inherit id;
      icon = "apps";
      order = 1000;
    }
    // removeAttrs e ["enable"])
  (lib.filterAttrs (id: e: lib.hasPrefix "custom-" id && on e) changes);

  #--- A url opens as a Helium app window, its app-id taken from the url
  finish = e:
    removeAttrs e ["order" "url"]
    // {width = e.width or geometry.width;}
    // lib.optionalAttrs (e ? url) {
      appId = e.appId or (heliumAppId e.url);
      command = ["helium" "--app=${e.url}"];
    };
in {
  inherit geometry;
  apps = map finish (lib.sort (a: b: a.order < b.order) (kept ++ custom));
}
