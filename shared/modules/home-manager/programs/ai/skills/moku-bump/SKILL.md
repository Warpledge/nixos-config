---
name: moku-bump
description: Bump or repair the source-built Moku manga reader and its Tsunagu backend in this repo (flake inputs, pnpmHash/vendorHash, patches, the Kototoro plugin pin). Use when a new Moku or Tsunagu release is out, when the user asks to update Moku, when a Moku build fails with a hash mismatch or a patch that no longer applies, after a nixpkgs update touches pnpm or Go fetchers, or when the Tsunagu sandbox log shows NoSuchMethodError naming org.skepsun.
---

# Moku bump

Moku is built from source in `shared/modules/home-manager/programs/media/moku/`, pinned
twice: the `moku` and `tsunagu` flake inputs in `flake.nix`, which must move together
(Tsunagu is the backend each Moku release ships with). The comments in `default.nix`
explain every override; this skill is the order of work.

## 1. Where things stand

```bash
bash <skill-dir>/scripts/status.sh
```

Prints pinned versus latest for Moku, Tsunagu and the Kototoro `plugin.jar` (built onto
the `repo` branch of skepsun/kototoro-parsers by deploy commits).

## 2. Bump

1. Update both URLs in `flake.nix` (`github:moku-project/Moku/vX`,
   `github:moku-project/Tsunagu/vY`), then `nix flake update moku tsunagu`.
2. Set `frontend.pnpmHash` and Tsunagu's `vendorHash` to
   `"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="` and build:
   ```bash
   bash <skill-dir>/scripts/build.sh
   ```
   It builds only Moku and prints each `got:` hash; paste it in, rebuild, repeat until it
   builds. Upstream's own `pnpmHash` matches upstream's nixpkgs, not ours, so it never works
   as-is.
3. Patches: a failed `--replace-fail` (the `KeywordTab.svelte` substitution) means upstream
   fixed it, so drop it. A failed hunk in `source-filters.patch` means regenerating it
   against the new source. For `tsunagu-fixes.patch` and `tsunagu/server.patch`, drop each
   part upstream now contains. What each part fixes, to test against the new release:
   - `tsunagu-fixes.patch`: popular and latest listings go through the suspend getters
     (0.4.1 and main at `9ab4475` called the Rx fetchers, which extensions-lib 1.6 sources
     leave unimplemented, so those pages came back empty); `ProtoBuf` is registered in the
     sandbox's Koin module as Mihon does (some sources fail at class init without it); and
     an installed extension loads from `extensions/` when its `jar-cache` file is gone
     (Moku's "Clear extension jar cache" otherwise breaks every source until reinstalled).
   - `tsunagu/server.patch`: a failed cover download is retried through the extension's
     own client, since some extensions hand out cover URLs only their interceptor can
     resolve.
4. Kototoro: bump the `plugin.jar` URL commit, its `hash` and the `# vX` comment together
   when status shows a newer build or the sandbox log has `NoSuchMethodError` naming
   `org.skepsun.`; jsoup and collection stay at the versions that plugin is built against.
   The sandbox runs only this pinned jar (`TSUNAGU_KOTOTORO_JAR`), never the one a repo
   index lists, so new parsers reach Moku through this bump and not through a repo sync.

## Checking a hash is really right

A successful build does not prove `pnpmHash` or `vendorHash` is correct: if the old
download is still in the store under the pinned hash, Nix never refetches, and the pin can
be stale while every local build passes. A fresh machine (the laptop) then fails. Verify by
forcing a refetch: set the hash to the `AAAA…` value above and run `build.sh`; the `got:`
must equal the pinned hash. A nixpkgs update that changes the pnpm or Go fetchers makes the
pin stale without any Moku change (first seen 2026-10-06).

Finish with `alejandra .` → `nix flake check`. Never touch the user's library or
extensions in `~/.local/share/{tsunagu,io.github.MokuProject.Moku}`.
