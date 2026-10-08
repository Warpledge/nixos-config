#!/usr/bin/env bash
# Check that a newly added app is wired everywhere the repo expects.
# Usage: check-app.sh <toggle> <module-path> [readme-label]
#   toggle        dotted hostConfig path, e.g. media.mpv
#   module-path   repo-relative module file or directory
#   readme-label  the [label] the README Components row and link block use
set -uo pipefail

toggle="${1:?toggle, e.g. media.mpv}"
module="${2:?module path}"
label="${3:-}"
repo="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo" || exit 1
status=0
pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; status=1; }

for host in desktop laptop; do
  if v="$(nix eval --json ".#nixosConfigurations.$host._module.specialArgs.hostConfig.$toggle" 2>/dev/null)"; then
    pass "$host hostConfig.$toggle = $v"
  else
    fail "$host hostConfig has no $toggle (add it to hosts/$host/settings.nix)"
  fi
done

if [ -e "$module" ]; then
  if git ls-files --error-unmatch "$module" >/dev/null 2>&1; then pass "$module exists and is staged"; else fail "$module is untracked: git add it"; fi
else
  fail "$module does not exist"
fi

# Several routers can mention the same toggle (AppArmor gates mpv's profile on media.mpv),
# so require the import line to carry the module's path relative to that router
found=""
while IFS= read -r router; do
  rel="./$(realpath --relative-to="$(dirname "$router")" "$module" 2>/dev/null)"
  if grep -F "hostConfig.$toggle" "$router" | grep -qF -- "$rel"; then found="$router"; break; fi
done < <(grep -rl --include=default.nix -F "hostConfig.$toggle" shared/modules)
if [ -n "$found" ]; then
  pass "imported in $found"
else
  fail "no lib.optionals hostConfig.$toggle [ ./…/$(basename "$module") ] import in any router"
fi

if [ -n "$label" ]; then
  if grep -qE "^\| \*\*.*\[$label\]" README.md; then pass "README Components row uses [$label]"; else fail "no README Components row with [$label]"; fi
  if grep -qE "^\[$label\]: http" README.md; then pass "README link [$label] defined"; else fail "no [$label]: link definition in README"; fi
else
  echo "skip  README (pass the label as a third argument)"
fi

exit "$status"
