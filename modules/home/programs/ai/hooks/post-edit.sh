#!/usr/bin/env bash
# PostToolUse (Write|Edit): format .nix, then hand Claude the repo checks
# it would otherwise have to remember.
in=$(cat)
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$in")
new=$(jq -r '.tool_input.new_string // .tool_input.content // empty' <<<"$in")
msg=()
case $f in
  *.nix) alejandra -q "$f" 2>/dev/null ;;
  */README.md) grep -qx -- '---' "$f" && msg+=("README.md now has a --- line; Zed pairs these like front-matter delimiters (CLAUDE.md). Remove it.") ;;
esac
case $f in */machines/*/settings.nix | */users/*/settings.nix)
  #--- Every machine through lib/settings.nix, which names typos and bad values
  r=${f%/machines/*}
  [[ $r == "$f" ]] && r=${f%/users/*}
  out=$(cd "$r" && for m in machines/*/; do
    m=${m%/} m=${m#machines/}
    [[ $m == _* ]] && continue
    # Only what follows the last `error:` line: the message, not the trace
    nix-instantiate --eval -E "(import ./lib/settings.nix {lib = import <nixpkgs/lib>;}).forMachine \"$m\" ? machine" 2>&1 >/dev/null |
      awk '/^ *error:/ { buf = ""; sub(/^ *error: */, ""); if ($0 != "") buf = $0 "\n"; next } NF { buf = buf $0 "\n" } END { printf "%s", buf }'
  done)
  [[ -n $out ]] && msg+=("lib/settings.nix rejects the settings after this edit:
$out")
  [[ $f == */users/_template/settings.nix ]] && msg+=("A new user toggle also goes in setup.sh's apps list, unless it's an essential (on in the template) or a ~/.local/opt bundle.")
  ;;
esac
if [[ $f == *.nix && $f != */modules/theme/* ]] && grep -qE '"#[0-9a-fA-F]{6}|rgba?\(' <<<"$new"; then
  msg+=("New color literal outside modules/theme/: Stylix owns theming (CLAUDE.md rule 5). Enable the program's Stylix target unless this is a deliberate override.")
fi
((${#msg[@]})) && jq -n --arg c "$(printf '%s\n' "${msg[@]}")" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
