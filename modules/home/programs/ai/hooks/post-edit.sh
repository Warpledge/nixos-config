#!/usr/bin/env bash
# PostToolUse (Write|Edit): format .nix, then hand Claude the repo checks
# it would otherwise have to remember.
in=$(cat)
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$in")
new=$(jq -r '.tool_input.new_string // .tool_input.content // empty' <<<"$in")
msg=()
case $f in
  *.nix)
    alejandra -q "$f" 2>/dev/null
    # Only the new text, so lines the edit didn't touch aren't re-reported
    long=$(awk 'length > 89 && /(^|[[:space:]])#/' <<<"$new")
    [[ -n $long ]] && msg+=("Comment lines over 89 columns (CLAUDE.md Comment Style); shorten or move above the code:
$long")
    ;;
  *.py)
    # Pyflakes and syntax errors only; the style rules report old code on every edit
    command -v ruff >/dev/null && out=$(ruff check --isolated --select F,E9 --output-format concise --quiet "$f" 2>&1)
    [[ -n $out ]] && msg+=("ruff:
$out")
    ;;
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
  msg+=("New color literal outside modules/theme/: DMS's matugen owns colours (CLAUDE.md rule 5). Use DMS's template for the app or add a matugen.templates entry, unless this is a deliberate fixed colour.")
fi
#--- Every machine and user folder in the repo, so a fork's own names are caught too
root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null)
names=
for d in "$root"/machines/*/ "$root"/users/*/; do
  d=${d%/} d=${d##*/}
  [[ $d == _template || $d == '*' ]] || names+=${names:+|}$d
done
if [[ $f == *.nix && $f =~ /(modules|lib)/ ]] &&
  { grep -qwE "${names:-eclipse|legion|warpledge}" <<<"$new" || grep -q /mnt/ <<<"$new"; }; then
  msg+=("A machine, user or /mnt/ path in a shared module: anyone installing this config gets it. Move it to machines/<name>/, or gate it on a setting.")
fi
((${#msg[@]})) && jq -n --arg c "$(printf '%s\n' "${msg[@]}")" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
