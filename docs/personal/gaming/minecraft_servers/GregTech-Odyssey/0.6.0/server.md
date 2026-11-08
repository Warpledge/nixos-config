# GTO 0.6.0 Server

A dedicated server on the laptop (legion), LAN only, with its own world created there
(2026-11-08). The desktop instance stays the source of mods and configs.

- **Folder:** `~/Documents/Minecraft_Servers/GregTech.Odyssey-0.6.0-dev27-server/` on
  the laptop
- **Runs in:** Omni Server as `gregtech-odyssey-0-6-0-dev27`
  (`~/.config/omni-server/servers/gregtech-odyssey-0-6-0-dev27.json`, added 2026-11-08):
  Java 25, 12288 MB heap, JVM flags preset None with the client's ZGC flags as extra
  flags, restart on crash
- **Command:** `gtoserver` (`log`, `stop`, `status`), from
  `machines/legion/minecraft-servers/gto-server.nix`; also in the `mcservers` picker. It
  only sees its own tmux session, so it won't report a server started from Omni Server
- **Port:** 25566, already open in `machines/legion/default.nix`. One server runs at a
  time, since the GTNH and TFG servers use it too
- **Loader:** Forge 1.20.1-47.4.20, read from the instance's `mmc-pack.json`
- **Java:** `pkgs.jdk25`, 12 GB heap, ZGC with compact object headers like the client
  ([java-and-launch.md](./java-and-launch.md))

## Building the folder

Each GTO release has a `GregTech-Odyssey-server.zip` beside the client zip
([0.6.0-dev-27](https://github.com/GregTech-Odyssey/GregTech-Odyssey/releases/tag/0.6.0-dev-27),
76.5 MB). It's a packwiz installer: `gto-installer/pack/mods/*.toml` name the 125
server-side jars with their hashes, `mods/` holds 4 more (GTOCore, ExtendedAE,
DataSyncLib, Botania), and `gto-installer/tools/` has the Forge installer. Its own
`install-mods.sh` downloads the jars; `gto server` copies them from the client instead.

On the desktop, with the game closed:

```bash
gto server GregTech.Odyssey-0.6.0-dev27 --zip ~/Downloads/GregTech-Odyssey-server.zip --tar
```

It writes `~/Documents/Minecraft_Servers/GregTech.Odyssey-0.6.0-dev27-server/` and a
`.tar.zst` of it beside the folder:

- The zip unpacked, with `mods/` replaced on each run.
- The pack's server jars, copied from the instance once each hash matches the index. A
  missing or changed jar is listed; `bash install-mods.sh` in the folder downloads it.
- Your jars from [overlay.json](../tools/overlay.json), except the `clientOnly` ones.
- `config/` and `defaultconfigs/` from the instance, so the server gets
  `gtocore-rules.txt`, the worldgen configs and the recipe datapack in
  `config/openloader/data/warpledge-gto/`.
- Forge, installed with the zip's installer, if it isn't there yet.
- `server.properties`, only when missing: port 25566, `online-mode=true`, whitelist on,
  2 players. Vanilla `difficulty` is left alone; GTO's rules file sets the pack's.

A rebuild never touches `world/`. The archive leaves out `world/`, `backups/` (Advanced
Backups' world copies), `logs/` and `crash-reports/`.

Tested on the desktop on 2026-11-08: the folder reached `Done` in 11 s and stopped
cleanly. A server that crashes while loading mods can hang instead of exiting, so the
restart loop never runs and `gtoserver stop` does nothing; stop it with `kill` on the
java process and read `crash-reports/`.

## First start on the laptop

1. Move the archive to the laptop (Syncthing or a USB stick) and unpack it:
   `mkdir -p <folder> && tar --zstd -xf <archive> -C <folder>`.
2. `nixm rebuild` there, so `gtoserver` exists.
3. Accept the EULA if the folder doesn't have it yet: `echo "eula=true" > eula.txt`.
4. Run `gtoserver`.
5. In the server console: `whitelist add <name>` and `op <name>`.
6. Connect from the desktop to `<laptop LAN IP>:25566`.

The world is created on the first start from the rules file the folder carried, so the
rules in [difficulty-rules.md](./difficulty-rules.md) apply. Check with the in-game View
Rules screen.

**Check `config/gtocore-rules.txt` before the first start.** The folder built on
2026-11-08 carried an older client file with only `preset = custom` and
`gtm.explosion_damages_terrain`, so the laptop's copy was set by hand to match
difficulty-rules.md before any world existed. `gto server` copies `config/` from the
client, so rebuilding a folder with no world yet takes the client's file as it is then.

## Client-only jars

The zip decides which of the pack's own mods run on a server, so `clientOnly` only
covers hand-added ones: EMF, ETF, Presence Footsteps (they crashed Cosmic Frontiers'
server), Sound Physics Remastered, Smooth Swapping, Keep Stepping and Resourcify. Cool
Rain runs on the server too (added 2026-11-08). A hand-added mod that crashes the server names a client class
(`net.minecraft.client...`) in the crash report; add its modId and rebuild the folder.
The client keeps every jar, so the list only changes the server.

## A new dev build

After `gto carry` into the new instance, download that release's server zip, run
`gto server <new instance> --zip <zip> --out <old folder> --tar` and move the archive
over the laptop's folder. The world stays; back it up first, since dev builds warn of
corrupted saves. A new Forge version also changes the `unix_args.txt` path and folder
name in `gto-server.nix`.
