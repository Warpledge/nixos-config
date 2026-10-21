# live file | jq --slurpfile old <last applied> --slurpfile new <declared>
#   --argjson locked <key paths the repo always resets>
# Used by modules/wm/dms-mutable.nix, modules/home/programs/editors/zed.nix and
# modules/home/programs/file-browsers/dux-files.nix
# Leaf paths; arrays and empty objects count as one value
def leafpaths:
  if type == "object" and length > 0
  then to_entries[] | [.key] + (.value | leafpaths)
  else [] end;
def get($p): try getpath($p) catch null;
def has_path($p):
  try (getpath($p[:-1]) | type == "object" and has($p[-1])) catch false;
def is_locked($p): any($locked[]; . as $l | $p[:($l | length)] == $l);
$old[0] as $o | $new[0] as $n
# The repo's value when locked, missing here, or never changed in the GUI
| reduce ($n | leafpaths) as $p (.;
    if is_locked($p) or (has_path($p) | not)
      or (($o | has_path($p)) and get($p) == ($o | get($p)))
    then setpath($p; $n | get($p)) else . end)
# Dropped from the repo and never changed in the GUI: drop it here too
| reduce ($o | leafpaths) as $p (.;
    if ((($n | has_path($p)) or is_locked($p)) | not)
      and get($p) == ($o | get($p))
    then delpaths([$p]) else . end)
