#=====================================================================#
# NIRI WINDOW RULES WITH THE USER'S CHANGES
#=====================================================================#
# window-rules.json's shared rules with the user's windowRules setting (Omni
# Settings' Window Rules page): a rule turned off or replaced by id, then the
# user's own custom- rules. Page labels stay on; rules.nix strips them.
{
  lib,
  user,
}: let
  changes = user.windowRules;
  on = r: r.enable or true;

  shared = lib.concatMap (r:
    if r ? include
    then [r]
    else let
      change = changes.${r.id} or {};
    in
      if !(on change)
      then []
      else if change ? matches
      then [(change // {inherit (r) id;})]
      else [r])
  (lib.importJSON ./window-rules.json);

  custom =
    lib.mapAttrsToList (id: r: r // {inherit id;})
    (lib.filterAttrs (id: r: lib.hasPrefix "custom-" id && on r) changes);
in
  shared ++ custom
