#!/usr/bin/env bash
# Check out a GitHub PR of this repo for review, build it, clean up after.
# Usage: pr.sh prep <N> | build <N> <machine> | clean <N>
set -uo pipefail

cmd="${1:-}" n="${2:-}"
[[ $cmd && $n =~ ^[0-9]+$ ]] || {
  echo "usage: pr.sh prep|build|clean <N> [machine]" >&2
  exit 2
}
repo="$(git rev-parse --show-toplevel)" || exit 1
ref="refs/review/pr$n"
work="${TMPDIR:-/tmp}/pr-review/$n"
base="$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main)"

case "$cmd" in
  prep)
    # pull/<N>/head exists on the base repo, so forks need no extra remote
    git -C "$repo" fetch -q origin "+pull/$n/head:$ref" || exit 1
    mkdir -p "$work"
    git -C "$repo" diff "$base...$ref" > "$work/pr.diff"
    echo "== commits"
    git -C "$repo" log --format='%h %s%n   (%an, parents: %p)' "$base..$ref"
    echo "== files"
    git -C "$repo" diff --stat "$base...$ref"
    echo "== merge into $base"
    if git -C "$repo" merge-tree --write-tree "$base" "$ref" >/dev/null; then
      echo clean
    else
      echo CONFLICT
    fi
    if [[ ! -d $work/tree ]]; then
      git -C "$repo" worktree add -q --detach "$work/tree" "$ref" || exit 1
    fi
    echo "== diff: $work/pr.diff ($(wc -l < "$work/pr.diff") lines)"
    echo "== worktree: $work/tree"
    ;;
  build)
    host="${3:?machine name}"
    [[ -d $work/tree ]] || { echo "run prep $n first" >&2; exit 1; }
    out="$work/build-$host.log"
    attr="nixosConfigurations.$host.config.system.build.toplevel"
    if nix build --no-link -L "$work/tree#$attr" > "$out" 2>&1; then
      echo "ok    $host"
    else
      echo "FAIL  $host (log: $out)"
      grep -E 'error:|SC[0-9]{4}' "$out" | head -20
      exit 1
    fi
    ;;
  clean)
    git -C "$repo" worktree remove --force "$work/tree" 2>/dev/null
    git -C "$repo" update-ref -d "$ref"
    echo "removed worktree and $ref (diff and logs stay in $work)"
    ;;
  *)
    echo "unknown command: $cmd" >&2
    exit 2
    ;;
esac
