# AppArmor profiles

Added 2026-09-23 (AppArmor 5.0.2). The profiles live in
`shared/modules/nixos/security/apparmor/`, one file per app, and every one starts in
`complain` mode: nothing gets blocked, and anything the profile would have denied is
logged as `apparmor="ALLOWED"`.

| Profile | Attaches to | Gated on |
| --- | --- | --- |
| `mpv` | `mpv`, `umpv` (both the wrapper and the real binary) | `media.mpv` |
| `yt-dlp` | `yt-dlp` run directly | always |
| `streamlink` | `streamlink` inside the Twitch GUI's bubblewrap sandbox | `media.streamlinkTwitchGui` |
| `evince` | `evince`, `evince-previewer` | always |
| `file-roller`, `unrar` | the GUI and the `unrar` CLI | always |
| `obsidian` | the `obsidian` launcher script | `office.obsidian` |
| `prismlauncher` | the real Prism binary, behind the mullvad-exclude wrapper | `gameLaunchers.prismlauncher` |

## Checking it works

After a rebuild, launch one of the apps and look at its label:

```bash
ps -eo label,comm | grep -v '^unconfined'   # e.g. "mpv (complain)  mpv"
sudo aa-status                              # every loaded profile and its mode
```

## Reading the log

```bash
journalctl -b -g 'apparmor="ALLOWED"' -o cat
journalctl -b -g 'apparmor="ALLOWED"' -o cat | grep 'profile="mpv"'
```

Each line names the profile, the path (`name=`) and the access (`requested_mask=`).
Legitimate accesses become rules in that app's module; anything reaching into
`~/.ssh`, browser profiles or other apps' config is what the profile is there to stop.

## Moving a profile to enforce

1. Use the app normally for a week or two, until its log lines stop showing up.
2. Change `state = "complain"` to `state = "enforce"` in its module and rebuild.
3. If the app then misbehaves, `journalctl -b -g 'apparmor="DENIED"'` shows what was blocked.

## Things to fix before enforcing

- **Launched apps inherit the profile.** Every profile allows `/nix/store/** ix`, so a
  browser opened from a link in Obsidian or Evince, or a viewer opened from File Roller,
  runs under that app's profile and would break under `enforce`. Rule `priority=` cannot
  carve out an exception: apparmor_parser 5.0.2 rejects overlapping exec rules with
  "profile has merged rule with conflicting x modifiers" whatever their priority.
- **mpv started by streamlink or by mpv's ytdl hook** stays in the parent's profile for
  the same reason, which is why `streamlink` carries mpv's rules through
  `abstractions/nix-mpv`.
- **Obsidian's vault path is hardcoded** (`~/Documents/obsidian-notes`); a new vault
  elsewhere needs a rule.

## Why some things are left out

- **unzip and tar** are not profiled: attachment is by path, and Nix builds run the same
  store paths (fetchzip runs unzip), so an enforced profile would break builds.
- **Browsers and Electron apps other than Obsidian** already run inside Chromium or Firefox
  sandboxes, and the upstream profiles for them (`apparmor-profiles` ships `obsidian`,
  `chrome`, `Discord` and others) are `flags=(unconfined)` stubs that only grant `userns`.
- **D-Bus is not mediated**: `services.dbus.implementation` is `broker`, and the
  dbus-broker in nixpkgs is built without libapparmor, so the `dbus,` rule in
  `abstractions/nix-desktop-app` grants nothing extra today.
