#=====================================================================#
# KY APPS
#=====================================================================#
#- One window for installing a nixpkgs package without a rebuild, keeping one
#- for good, and reading a failed rebuild's error back to Ky's own files.
#- Kept apps live in packages.json, which the window writes and this module
#- reads, so no Nix syntax is ever edited by a tool.
{
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (ps: [ps.pygobject3]);

  app = pkgs.stdenvNoCC.mkDerivation {
    pname = "ky-apps";
    version = "1";
    src = ./.;

    nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.makeWrapper pkgs.gobject-introspection];
    buildInputs = [pkgs.gtk4 pkgs.libadwaita];

    dontBuild = true;
    installPhase = ''
      mkdir -p $out/lib/ky-apps $out/bin
      cp app/main.py app/backend.py $out/lib/ky-apps/
      substituteInPlace $out/lib/ky-apps/backend.py \
        --subst-var-by nix ${pkgs.nix} \
        --subst-var-by search ${pkgs.nix-search-tv}
      makeWrapper ${python}/bin/python3 $out/bin/ky-apps \
        --add-flags $out/lib/ky-apps/main.py
    '';
  };

  #--- packages.json is {group: [attr]}, the shape userPackages already uses
  kept = lib.concatLists (lib.attrValues (builtins.fromJSON (builtins.readFile ./packages.json)));
  keptPackages = map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) kept;
in {
  home.packages = [app] ++ keptPackages;

  xdg.desktopEntries.ky-apps = {
    name = "Apps";
    genericName = "Package Manager";
    comment = "Install packages without a rebuild, and keep the ones you want";
    exec = "ky-apps";
    icon = "system-software-install";
    categories = ["System" "Settings"];
  };
}
