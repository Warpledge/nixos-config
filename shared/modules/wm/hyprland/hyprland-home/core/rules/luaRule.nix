#=====================================================================#
# RULE STRING → LUA RULE TABLE
#=====================================================================#
# Turns "match:class ^(x)$, float on, size 600 600" into the table that
# hl.window_rule / hl.layer_rule take. Fields are split on ", ", so a value
# must not contain one.
{lib}: let
  inherit (builtins) elemAt match fromJSON;

  #--- on/off become booleans (animation takes the literal string "off");
  #--- ignore_alpha is the only numeric field the rule files use.
  toValue = key: v:
    if key != "animation" && v == "on"
    then true
    else if key != "animation" && v == "off"
    then false
    else if key == "ignore_alpha"
    then fromJSON v
    else v;

  #--- hyprlang needed quotes around multi-word values ("slide bottom")
  unquote = v: let
    q = match ''"(.*)"'' v;
  in
    if q == null
    then v
    else elemAt q 0;

  addField = acc: field: let
    kv = match "([^ ]+) (.*)" field;
    key = elemAt kv 0;
    value = unquote (elemAt kv 1);
  in
    if kv == null
    then throw "hyprland rule field without a value: ${field}"
    else if lib.hasPrefix "match:" key
    then lib.recursiveUpdate acc {match.${lib.removePrefix "match:" key} = value;}
    else acc // {${key} = toValue key value;};
in
  rule: lib.foldl' addField {} (lib.splitString ", " rule)
