# AppImage Wraps

Apps packaged from an upstream AppImage with `appimageTools` instead of
`pkgs.<name>` or the `~/.local/opt` pattern. Unlike the bundles in
`local-binary-installs.md`, nothing lives outside git: the AppImage is
hash-pinned and fetched into the store, so a fresh machine needs no manual
restore step.

| App | Module | Version | Why not nixpkgs |
| --- | --- | --- | --- |
| fee[dB]ack | `home-manager/programs/gaming/feedback.nix` | 0.3.0-unstable-2026-07-23 | not in nixpkgs; upstream ships only AppImages |
| Mangayomi | `home-manager/programs/media/mangayomi.nix` | 0.9.7 | nixpkgs had 0.9.2 on 2026-09-23; upstream tagged 0.9.7 on 2026-09-22 |
| Streamlink Twitch GUI | `home-manager/programs/media/streamlink-twitch-gui.nix` | 2.5.3 | not in nixpkgs under any name, checked 2026-09-22 |

## The pattern

`appimageTools.wrapType2` runs the AppImage; `appimageTools.extract`
unpacks the same `src` alongside it only so the desktop entry and icon can be
installed. Both take the same `pname`, `version` and `src`, so they stay in
step.

Two things differ per app and are worth checking when adding another:

- **The desktop entry's `Exec`.** Mangayomi ships `Exec=/usr/bin/mangayomi`,
  which has to be rewritten to the bare command the wrapper puts on PATH. Others
  ship a bare command already and need no rewrite, as Streamlink Twitch GUI does.
- **The icon name.** Some AppImages ship a generic `logo.png` with `Icon=logo`,
  which wants renaming plus a matching `substituteInPlace` so it cannot collide
  with another app's icon. Mangayomi's is already `mangayomi.png`.

Use `--replace-fail` for both, so a silent no-op turns into a build error if
upstream changes the line.

## A non-executable AppRun

Some AppImages ship `AppRun` as mode 444, so `wrapType2` builds a launcher that
dies with `AppRun: Permission denied` before the app's own binary runs. Hit with
Unyo 0.6.7 on 2026-09-21; Mangayomi's is 555 and needs none of this. Check with
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
    m = import ./shared/modules/home-manager/programs/media/mangayomi.nix { inherit pkgs; };
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

Mangayomi prompts to download updates itself, and other AppImages do the same.
Always decline: the binary sits in the read-only store, so the update either
fails outright or writes a copy into the data dir that shadows the packaged one,
and the config stops describing what actually runs. Bump the `version` and
`hash` in the module instead.

## Mangayomi's Mihon proxy server

Mihon extensions need a proxy server bundle (a Temurin JRE plus
`MExtensionServer-vX.Y.Z-rN.jar`) that the app downloads itself into
`~/Documents/Mangayomi/extension_server/`, about 163 MB. Settings → Extensions →
Android Proxy Server (Mihon) → Download.

The bundled JRE is an unpatched generic-Linux build asking for
`/lib64/ld-linux-x86-64.so.2`, which works here only because
`programs.nix-ld.enable` in `nixos/services/runners.nix` puts a shim there. It
runs from a plain shell as well as inside the AppImage sandbox, so there is no
need to add a JDK to `extraPkgs`; that would just duplicate ~200 MB of Java.
Verified with Temurin 21.0.12 and server 1.0.7 on 2026-09-21.

The bundle is outside git and outside the store, so a fresh machine has to click
Download again. The app's "Choose location" and "Detect files in selected
folder" buttons can point at an existing copy if one gets carried across.

The `Advanced` section's `http://127.0.0.1:8080` is the M-Extension-Server
address, used only when proxying through a separate Android device. Leave it
alone: `steamwebhelper` already holds 8080 on the desktop.

## Going back to nixpkgs

Mangayomi is in nixpkgs and updated roughly monthly (0.7.0 in March 2026, 0.7.2
in July, 0.8.0 on 2026-08-29, 0.9.2 by 2026-09-23). Once it reaches the version
pinned in the module, the module can go back to a one-line
`home.packages = [pkgs.mangayomi];` and the version bumps stop being yours.
