# GTNH 2.9.0 Server

New world, no migration. The 2.8.4 server stays at
`~/Documents/Minecraft_Servers/GT_New_Horizons_2.8.4_Server_Modified` on the laptop as a
backup; the new one is a separate folder.

## Build

1. Download the 2.9.0 **Java 17-26** server zip from
   [the version history page](https://www.gtnewhorizons.com/version-history/) and unpack
   it to `~/Documents/Minecraft_Servers/GT_New_Horizons_2.9.0_Server_Modified`.
2. Copy the server-side mods from [mods.md](./mods.md): every row marked **B**, using the
   123Technology's PR build; Twist uses its 0.8.0 release. Leave out **C**-only rows.
3. `machines/legion/minecraft-servers/gtnh-server.nix` now points its `serverDir` and
   header comment at that folder. The Java path (`jdk25`), the JVM args and the tmux
   crash loop are unchanged.

## Local test on the desktop

The same folder is unpacked on eclipse, with the mods and configs below copied over, for
testing before it goes to the laptop:

- `start.sh` in the server folder runs the server with 6G heap and a crash-restart loop.
  The laptop module raises it to 12G.
- `~/.local/bin/gtnh` is a local copy of the laptop launcher: `gtnh` starts or attaches
  the tmux session, `gtnh log`, `gtnh stop`, `gtnh status`.
- The client connects to `localhost:25566`.

This local copy exists only for testing; the laptop gets the `gtnh` command from
`machines/legion/minecraft-servers/gtnh-server.nix` after the next rebuild.

## server.properties

- `server-port=25566`
- `view-distance=8`
- `max-tick-time=0`: stops the watchdog killing the server during heavy worldgen

## Mods the server needs on top of the pack

From [mods.md](./mods.md), the **B** rows:

- GTNL 0.2.7-rc2.1 with GTNLLib 1.1.3 and BetterQuestingAPI 1.1.3, GTNHRates 1.12.0-2.9,
  Twist Space `TwistSpaceTechnology-0.8.0.jar` (release 2026-11-02),
  123Technology `OTHTechnology-2.2.0.1-git.3+2b1a0b5fbd.jar` (PR #269), EZMiner 6.2,
  EZNuclear 1.1.1, EZStorage 1.8.2, NH-Utilities 1.7.0, Programmable Hatches 0.2.1p2-beta
- ElytraMining 1.2.0.1, Trash Slot 1.0.31, SharedProspecting 2.0.4
- YesSteveModel Unofficial 1.9, with its models in `config/ysmu/custom/`
- Waystones-X 1.0.16, MIAOKATZE Core 0.2.0, GT-Miao-Blueprint 0.3.0,
  GT-Steam-Reborn 2.1.1, GT-Interesting-Thing 2.1.0, GT-Simple-Wireless-Network 2.1.0
- The EZStorage script `scripts/simplestorage_gregified.zs` must be on the server too, or
  the recipes differ from the client.

BetterSprinting and deconfigintegration are dropped (see mods.md). LagGoggles is still
not installed.

2.9.0 supplies its own lwjgl3ify, GTNHLib, FalsePatternLib and Extreme Sound Muffler
Legacy, so do not copy the 2.8.4 versions of those to the server.

The configs copied with the mods are `config/GTNotLeisure/` (without `client.cfg`),
`123Technology.cfg`, `elytra_mining.cfg`, `EZNuclear.cfg`, `ezstorage.cfg`,
`gtnhrates.cfg`, `programmablehatches.cfg`, `proghatches.mixin.properties`,
`TwistSpaceTechnology.cfg`, `visualprospecting.cfg`, `NHUtilities/`, `waystones.cfg`
(`xpBaseCost=-1`) and the `gtit/`, `gtmb/`, `gtsr/` and `gtswn/` folders.

## ServerUtilities

The client has a copy at `.minecraft/serverutilities/` for singleplayer and LAN worlds;
the server has its own. Apply the same edits to both, or the hosted world behaves
differently from a local one.

`serverutilities.cfg`:

- `B:chunk_claiming=true` [false]
- Under `commands`, all default `false`, set to `true`: `B:home`, `B:warp`, `B:rtp`,
  `B:spawn`, `B:tpa`, `B:back`
- `ranks { B:enabled=false }` stays off for a two-player server

`server/ranks.txt` only matters if ranks are turned on. If they are, the 2.8.4 values
were claims 5000, chunkloaders 5000 for every rank, homes 3 with no warmup or cooldown,
and cross-dimension homes. Note that 2.9's file uses the full
`serverutilities.claims.max_chunks` key form, and it no longer lists the teleport
warmup keys at all.

## Waystones

- `config/waystones.cfg` → `xpBaseCost=-1` disables the XP cost. The file appears once
  the mod is installed.

## World

Generate a fresh world on the server and copy it nowhere. 2.9's terrain, ore mix and
CropsNH data only exist in worlds created under 2.9, and an old world keeps its 2.8
generation. If the old 2.8.4 world is ever wanted, its server folder and the 2.8.4
instance are both still intact.
