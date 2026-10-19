# FreeTube

<!-- Claude Code loads this file when it reads a file in this folder. -->

`programs/media/freetube/` — `settings.nix` (mirrored from the app), `blocked-channels.nix` (~870 channel ids in one flat list, sorted by lowercased name under `LC_ALL=C`) and `youtube-dispatch.nix`, the link handler `mime.nix` points `webLinks` at. The first two are **mirrored**: the home-manager module copies `hm_settings.db` over `settings.db` **only when the declared content changes**, and FreeTube rewrites that file from memory when it exits, so close FreeTube before rebuilding, or the copy is clobbered and stays clobbered until the module changes again. Blocklist entries are emitted with a `preferredName` and a placeholder `icon`, because FreeTube re-resolves every entry missing either one, at one API call each. Subscriptions, profiles, playlists and history are **not** in the repo: they are personal data and this flake is public. `nixm freetube-backup` exports them to a dated folder under `~/SyncBackups/<hostname>/FreeTube` instead, in FreeTube's own Export format so its Import reads them back.

**Update FreeTube state** (blocklist or settings), asked for as "I blocked more" /
"sync freetube": the `freetube-sync` skill has the steps and checks; FreeTube stays closed
throughout. `~/.config/FreeTube/settings.db` is a NeDB append-log where a later line
with the same `_id` wins, so reduce it before reading:
`jq -rs 'reduce .[] as $x ({}; .[$x._id] = $x.value)' settings.db`. The blocklist sits
inside it as `channelsHidden`, a JSON **string** needing `fromjson`. A `nixm freetube-backup`
folder is restored through the app's Settings → Data Settings → Import, not by copying files
into place.
