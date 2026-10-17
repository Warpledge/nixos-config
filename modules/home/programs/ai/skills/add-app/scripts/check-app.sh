#!/usr/bin/env bash
# Check that a newly added app is wired everywhere the repo expects.
# Usage: check-app.sh <toggle> <module-path> [readme-label]
#   toggle        dotted settings path, e.g. media.mpv
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

#--- A template defines every toggle: users/ for an app, machines/ for a service
in_template() { nix-instantiate --eval --strict -E "(import ./$1/_template/settings.nix).$toggle or null" 2>/dev/null; }
if [[ $(in_template users) =~ ^(true|false)$ ]]; then
  scope=users expr="m: m.users.\${m.mainUser}.$toggle"
elif [[ $(in_template machines) =~ ^(true|false)$ ]]; then
  scope=machines expr="m: m.$toggle"
else
  scope="" expr=""
  fail "$toggle is in neither users/_template/settings.nix (apps) nor machines/_template/settings.nix (services)"
fi
[[ -n $scope ]] && pass "$toggle defined in $scope/_template/settings.nix"

for m in machines/*/; do
  m=${m%/} m=${m#machines/}
  [[ $m == _* || -z $expr ]] && continue
  if v="$(nix eval --json ".#nixosConfigurations.$m._module.specialArgs.machine" --apply "$expr" 2>/dev/null)"; then
    pass "$m: $toggle = $v"
  else
    fail "$m does not evaluate $toggle (nix eval .#nixosConfigurations.$m shows why)"
  fi
done

if [[ $scope == users ]]; then
  if grep -qF "|$toggle|" setup.sh; then pass "setup.sh offers $toggle"; else echo "note  setup.sh's apps list doesn't offer $toggle (fine for an essential or a ~/.local/opt bundle)"; fi
fi

if [ -e "$module" ]; then
  if git ls-files --error-unmatch "$module" >/dev/null 2>&1; then pass "$module exists and is staged"; else fail "$module is untracked: git add it"; fi
else
  fail "$module does not exist"
fi

# Several routers can mention the same toggle (AppArmor gates mpv's profile
# on media.mpv), so require the import line to carry the module's path
# relative to that router
#--- Home routers read `user.`, system ones `anyUser.` (apps) or `machine.` (services)
pattern="(user|anyUser|machine)\.${toggle//./\\.}\b"
found=""
while IFS= read -r router; do
  rel="./$(realpath --relative-to="$(dirname "$router")" "$module" 2>/dev/null)"
  if grep -E "$pattern" "$router" | grep -qF -- "$rel"; then found="$router"; break; fi
done < <(grep -rlE --include=default.nix "$pattern" modules)
if [ -n "$found" ]; then
  pass "imported in $found"
else
  fail "no lib.optionals user.$toggle [ ./…/$(basename "$module") ] import in any router"
fi

if [ -n "$label" ]; then
  if grep -qE "^\| \*\*.*\[$label\]" README.md; then pass "README Components row uses [$label]"; else fail "no README Components row with [$label]"; fi
  if grep -qE "^\[$label\]: http" README.md; then pass "README link [$label] defined"; else fail "no [$label]: link definition in README"; fi
else
  echo "skip  README (pass the label as a third argument)"
fi

exit "$status"
