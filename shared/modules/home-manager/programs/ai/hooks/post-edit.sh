#!/usr/bin/env bash
# PostToolUse (Write|Edit): format .nix, then hand Claude the repo checks it would otherwise have to remember.
in=$(cat)
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$in")
new=$(jq -r '.tool_input.new_string // .tool_input.content // empty' <<<"$in")
msg=()
case $f in
  *.nix) alejandra -q "$f" 2>/dev/null ;;
  */README.md) grep -qx -- '---' "$f" && msg+=("README.md now has a --- line; Zed pairs these like front-matter delimiters (CLAUDE.md). Remove it.") ;;
esac
case $f in */hosts/*/hostConfig/core.nix)
  r=${f%/hosts/*}
  msg+=("Toggle lines that differ between desktop (<) and laptop (>); each must be deliberate:
$(diff "$r"/hosts/{desktop,laptop}/hostConfig/core.nix | grep '^[<>].*=')") ;;
esac
if [[ $f == *.nix && $f != */modules/theme/* ]] && grep -qE '"#[0-9a-fA-F]{6}|rgba?\(' <<<"$new"; then
  msg+=("New color literal outside shared/modules/theme/: Stylix owns theming (CLAUDE.md rule 5). Enable the program's Stylix target unless this is a deliberate override.")
fi
((${#msg[@]})) && jq -n --arg c "$(printf '%s\n' "${msg[@]}")" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
