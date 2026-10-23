#!/usr/bin/env bash
# PreToolUse (Bash): enforce CLAUDE.md rule 11 and keep tracked-file edits on
# Edit/Write, where post-edit.sh formats and checks them.
cmd=$(jq -r '.tool_input.command // empty')
deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}
#--- rm with a variable, or chained onto other commands
if grep -qE '(^|[;&|(]|\$\()[[:space:]]*(sudo[[:space:]]+)?rm[[:space:]]' <<<"$cmd" &&
  { [[ $cmd == *$'\n'* ]] || grep -qE '[$`;|]|&&' <<<"$cmd"; }; then
  deny "CLAUDE.md rule 11: rm takes literal absolute paths, no \$VAR, and runs as its own command, not chained or in a script."
fi
#--- In-place writes to a file git tracks
repo=${CLAUDE_PROJECT_DIR:-$PWD}
targets=$(grep -oE '(>>?|tee([[:space:]]+-a)?)[[:space:]]*[^[:space:];&|<>]+' <<<"$cmd" |
  sed -E 's/^(>>?|tee([[:space:]]+-a)?)[[:space:]]*//')
#--- The arguments of sed -i / perl -i, up to the next ; & or |
targets+=$'\n'$(grep -oE '(^|[[:space:];&|])(sed[[:space:]]+(-[a-zA-Z]*i|--in-place)|perl[[:space:]]+-[a-zA-Z]*i)[^;&|]*' <<<"$cmd" |
  tr -s '[:space:]' '\n' | grep -vE '^-')
while IFS= read -r p; do
  [[ -z $p || $p == /dev/* || $p == \&* ]] && continue
  if [[ -f $p ]] && git -C "$repo" ls-files --error-unmatch -- "$(realpath "$p")" &>/dev/null; then
    deny "$p is tracked: edit it with Edit or Write so the post-edit hook formats and checks it (CLAUDE.md)."
  fi
done <<<"$targets"
exit 0
