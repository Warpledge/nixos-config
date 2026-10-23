#=====================================================================#
# USER PACKAGES
#=====================================================================#
#- The nixpkgs packages in the user's userPackages categories, added from
#- NixOS Settings' Packages tab; a dotted name reaches a package set's member
{
  lib,
  pkgs,
  user,
  ...
}: {
  home.packages =
    map (
      name:
        lib.attrByPath (lib.splitString "." name)
        (throw "userPackages: nixpkgs has no package called ${name}")
        pkgs
    )
    (lib.unique (lib.concatLists (lib.attrValues user.userPackages)));
}
