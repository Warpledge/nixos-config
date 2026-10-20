# NixOS modules

<!-- Claude Code loads this file when it reads a file in this folder. -->

NixOS Settings' root helper (`system/user/nixos-settings-helper.nix`) is described in
`modules/home/programs/system/nixos-settings/CLAUDE.md`; read it before changing the helper.

## Network

- DNS: systemd-resolved (stub listener on 127.0.0.53, opportunistic DNS-over-TLS, no fallback servers) + NetworkManager
- WiFi: iwd, IPv6 privacy, random MAC
- Firewall: `modules/nixos/network/firewall.nix` opens the ports in the machine's `firewall.openTCPPorts`/`openUDPPorts` (TCP 7777, Terraria, on both machines); other ports open with the module that uses them. When `printing.enable` is set, `services/hardware/printing.nix` turns on Avahi, which opens UDP 5353. `services/ssh.nix` opens TCP 22, so it's open only while the machine's `ssh.enable` loads that module; the laptop's `default.nix` opens TCP 25566 for its Minecraft servers; Steam's remote-play and local-transfer options in `gaming/steam.nix` open its LAN ports. FlareSolverr, Suwayomi, Open WebUI (port 8091) and its mcp-nixos server (8092) listen on 127.0.0.1 only. When `syncthing.enable` is set, the Syncthing module also opens TCP/UDP 22000 and UDP 21027. When `sunshine.enable` is set, `servers/sunshine.nix` opens TCP 47984, 47989 and 48010 plus UDP 47998–48000, 48002 and 48010 (the module's own list minus 47990, so the web UI stays local), and the module turns on Avahi, which opens UDP 5353.
- Mullvad: `mullvad.enable` in the machine's settings (WireGuard, quantum resistance, multihop, DAITA; lockdown mode cuts all traffic while the tunnel is down). Settings are applied with the `mullvad` CLI from a oneshot unit, not by templating `settings.json`, which the daemon rewrites. Relay and entry selection are deliberately unmanaged so exits can be switched by hand. `mullvad.splitTunnel` names apps routed around the VPN; `split-tunnel.nix` puts each wrapper in the profile its app is installed in (each user's home profile, for the apps that user has on), since the home profile outranks `/run/current-system/sw/bin` in PATH and a system wrapper for an HM package is silently shadowed. Steam sets `no_new_privs` on what it launches, which blocks the setuid `mullvad-exclude` helper, so the wrapper skips the helper when `/proc/self/cgroup` already shows `mullvad-exclusions` (Steam is split-tunnelled itself). If a Steam shortcut to a split-tunnelled app closes instantly with nothing in the app's logs, its stderr is in `~/.local/share/Steam/logs/console-linux.txt`, and `gameprocess_log.txt` beside it has the spawned command line; reproduce with `setpriv --no-new-privs <wrapper> true`. Why DataPacket exits read as London, and the relay to pick instead, is in `docs/security/mullvad.md`.
- `network/blockers.nix` — hosts-level blocklists, imported while the machine's `blocklist.enable` is on, with `blocklist.extra` as its extra categories

## Security

Audit tooling is `lynis` (configuration) and `sbomnix`/`vulnxscan` (CVE scanning against the real closure, via osv.dev). **Do not go back to `vulnix`**: it only knows NVD's legacy JSON 1.1 feeds, which return 403 since their retirement, so every run ends in a `ConnectionError` traceback. Verified 2026-09-22, when the NVD API 2.0 answered 200 from the same machine.

**AppArmor profiles** live in `modules/nixos/security/apparmor/`, one module per app (`archives.nix` holds file-roller and unrar), gated on `anyUser.<app>` where the app has a toggle, all in `complain` mode. Attach them by store-path glob (`/nix/store/*-mpv-*/bin/mpv`), never to a binary Nix builds also run (unzip, tar). `nix flake check` does not parse profiles, so test-compile them with the `apparmor-check` skill before handing back. Log reading, the enforce procedure and known gaps are in `docs/security/apparmor.md`.

The machine's `ssh.enable` gates `nixos/services/ssh.nix`, which owns both sshd and fail2ban: key-only auth for the machine's users, no root login, no forwarding, ed25519 host key, and the fail2ban sshd jail. Keys come from each user's `ssh.authorizedKeys`. An assertion refuses to build when the toggle is on and no user lists a key, since password and keyboard-interactive auth are both off and there would be no way in.
