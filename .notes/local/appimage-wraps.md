# AppImage Wraps

Apps packaged from an upstream AppImage with `appimageTools` instead of
`pkgs.<name>` or the `~/.local/opt` pattern. Unlike the bundles in
`local-binary-installs.md`, nothing lives outside git: the AppImage is
hash-pinned and fetched into the store, so a fresh machine needs no manual
restore step.

| App | Module | Version | Why not nixpkgs |
| --- | --- | --- | --- |
| fee[dB]ack | `home-manager/programs/gaming/feedback.nix` | 0.3.0-unstable-2026-07-23 | not in nixpkgs; upstream ships only AppImages |
| Streamlink Twitch GUI | `home-manager/programs/media/streamlink-twitch-gui.nix` | 2.5.3 | not in nixpkgs under any name, checked 2026-09-22 |

## The pattern

`appimageTools.wrapType2` runs the AppImage; `appimageTools.extract`
unpacks the same `src` alongside it only so the desktop entry and icon can be
installed. Both take the same `pname`, `version` and `src`, so they stay in
step.

Two things differ per app and are worth checking when adding another:

- **The desktop entry's `Exec`.** Some ship an absolute `Exec=/usr/bin/<name>`,
  which has to be rewritten to the bare command the wrapper puts on PATH. Others
  ship a bare command already and need no rewrite, as Streamlink Twitch GUI does.
- **The icon name.** Some AppImages ship a generic `logo.png` with `Icon=logo`,
  which wants renaming plus a matching `substituteInPlace` so it cannot collide
  with another app's icon.

Use `--replace-fail` for both, so a silent no-op turns into a build error if
upstream changes the line.

## A non-executable AppRun

Some AppImages ship `AppRun` as mode 444, so `wrapType2` builds a launcher that
dies with `AppRun: Permission denied` before the app's own binary runs. Hit with
Unyo 0.6.7 on 2026-09-21. Check with
`ls -l <extracted>/AppRun` before assuming a launch failure is a missing
library.

The fix is to drop to `wrapAppImage`, which is what `wrapType2` calls once it
has extracted, and hand it a tree with the bit restored:

```nix
fixed = pkgs.runCommand "${pname}-${version}-extracted-fixed" {} ''
  cp -r ${contents} $out
  chmod -R u+w $out
  chmod +x $out/AppRun
'';
```

**Run the wrapped binary before calling it done.** A derivation that builds and
installs `bin/`, a desktop entry and an icon can still fail to launch; only
executing it catches this class of problem.

## Bumping a version

Change `version`, then get the new hash. `nix store prefetch-file` fails on this
machine with `Resolving timed out` (the nix daemon's DNS, not the network, since
curl reaches the same URL). The way around it is a deliberately wrong hash:

```bash
nix build --impure --no-link --expr '
with import <nixpkgs> {};
fetchurl {
  url = "https://github.com/OWNER/REPO/releases/download/vX.Y.Z/Name-vX.Y.Z-linux.AppImage";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}'
```

The error prints `got: sha256-...`, which is the value to paste in.

Build a module on its own without a full rebuild:

```bash
nix build --impure --no-link --print-out-paths --expr '
let pkgs = import <nixpkgs> {};
    m = import ./shared/modules/home-manager/programs/media/streamlink-twitch-gui.nix { inherit pkgs; };
in builtins.head m.home.packages'
```

Then check `bin/`, `share/applications/*.desktop` and
`share/icons/hicolor/512x512/apps/` in the result.

A rolling release tag is a different case. fee[dB]ack publishes every build to
the same `nightly` tag under the same filename, so the pinned URL stays valid
while its contents change underneath it. The fetch then fails with a hash
mismatch on the next rebuild, which is the cue to bump the date in `version`
and paste the `got:` hash in, not a sign anything is broken.

## In-app updaters

Some AppImages prompt to download updates themselves.
Always decline: the binary sits in the read-only store, so the update either
fails outright or writes a copy into the data dir that shadows the packaged one,
and the config stops describing what actually runs. Bump the `version` and
`hash` in the module instead.

