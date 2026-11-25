# GTNH 2.9.0 Server

New world, no migration. The 2.8.4 server stays at
`~/Documents/Minecraft_Servers/GT_New_Horizons_2.8.4_Server_Modified` on the laptop as a
backup; the new one is a separate folder.

## Build

1. Download the 2.9.0 **Java 17-26** server zip from
   [the version history page](https://www.gtnewhorizons.com/version-history/) and unpack
   it to `~/Documents/Minecraft_Servers/GT_New_Horizons_2.9.0_Server_Modified`.
2. Copy the server-side mods from [mods.md](./mods.md): every row marked **B**. Leave out
   **C**-only rows.
3. `machines/legion/minecraft-servers/gtnh-server.nix` now points its `serverDir` and
   header comment at that folder. The Java path (`jdk25`), the JVM args and the tmux
   crash loop are unchanged.

## Local server on the desktop

The laptop hosts the server, and the desktop is client only apart from debugging. For that,
the same folder is unpacked on eclipse with the mods and configs below copied over. It was
the copy in use on 2026-11-05 and wasn't on the desktop on 2026-11-06. When it's there:

- The Omni Server app runs it as `gtnh-2-9-0`
  (`~/.config/omni-server/servers/gtnh-2-9-0.json`): Java 25, 6144 MB heap, the G1 preset
  and the translation agent from [java-and-launch.md](./java-and-launch.md#jvm-args).
- `start.sh` in the server folder is the older way to run it, with 6G heap, the same agent
  and a crash-restart loop. The laptop module uses 12G.
- `~/.local/bin/gtnh` is a local copy of the laptop launcher: `gtnh` starts or attaches
  the tmux session, `gtnh log`, `gtnh stop`, `gtnh status`. It only sees that tmux session,
  so it won't report a server started from Omni Server.
- The client connects to `localhost:25566`.

The laptop gets the `gtnh` command from
`machines/legion/minecraft-servers/gtnh-server.nix` after the next rebuild. Its copy was
compared on 2026-11-05 and has the server-side edits from
[config-tweaks.md](./config-tweaks.md) (mobs, GregTech, Gendustry and the like), with the
old files in `~/Documents/Minecraft_Servers/config-before-server-tweaks-2026-11-05.tar.gz`.
Since the 2026-11-19 sync below it differs from this page only on `level-name`
(`World`). Its Omni Server entry
uses 12288 MB and already loads the translation agent.

## server.properties

- `server-port=25566`
- `view-distance=10`
- `max-tick-time=0`: stops the watchdog killing the server during heavy worldgen
- `level-name=World3`: the folder the next generated world will use. The server keeps no
  persistent world while the pack is still being tuned, so this is a name waiting for a
  world rather than one in use.

## Mods the server needs on top of the pack

The list is every `"side": "B"` entry in [mod-sources.json](./mod-sources.json) with the
same jar the client has; versions live there and in [mods.md](./mods.md), not here. A
side-B mod missing on either side, or at a different version, gets the client rejected
at login. Two jars differ on purpose:

- OmniOcular Unofficial uses `OmniOcularUnofficial-<version>-server.jar` from the same
  GitHub release as the client's full jar.
- `JourneyMapServer1.0.5_MC1.7.10.jar` is server only and accepts any client.

`InGameInfoXML-2.9.8.jar` stays on the server from the pack's own server zip, though the
client dropped it for InfoHUD; its network check lets a client without it in.

2.9.0 supplies its own lwjgl3ify, GTNHLib, FalsePatternLib and Extreme Sound Muffler
Legacy, so do not copy the 2.8.4 versions of those to the server.

### Synced from the client on 2026-11-19

The desktop copy of the laptop's server folder was brought level with the client: 18
stale or removed jars out (EZMiner 6.3, the 11-08 Miao set, GTNL rc2.1, GTIT, ElytraMining,
SharedProspecting and the rest) and 26 in, including Omni Miner, Benzene Fuels, Patchee,
Thaumic Duality Interface, Wildcard Pattern, AE2 Wireless Transceiver, EZStorage Craft
Fix and LagGoggles. The old jars, the old `123Technology.cfg` and a tarball of `config/`
and `scripts/` are in `backups/pre-sync-2026-11-19/` in the server folder. Copy that
folder back to the laptop to apply it there. GTIT was tried on 2026-11-24 and removed the
same day as too cheaty; see
[mods.md](./mods.md#gt-interesting-thing-tried-and-removed-on-2026-11-24).

Configs copied from the client (side-B mods, plus every edit in
[config-tweaks.md](./config-tweaks.md) the server enforces):

- `123technology.cfg` (lowercase; see [config-tweaks.md](./config-tweaks.md#balance-edits-2026-11-03)),
  `GregTech/GregTech.cfg`, `gtmb-stargate-rules.cfg`, `HungerOverhaul/HungerOverhaul.cfg`,
  `SpecialMobs.cfg`, `InfernalMobs.cfg`, `Thaumcraft.cfg`, `tc4tweak.cfg`, `rwg2.cfg`,
  `neoecoae.cfg`, `Omni Ocular Unofficial.cfg`
- `GTNotLeisure/{general,item,machine,recipe,re_avaritia,gtnllib}.cfg`, and the `gtsr/`,
  `gtswn/`, `gtmb/`, `ae2thing/`, `miaokatzecore/` and `ThaumcraftMobAspects/` folders.
  `gtsr/industrial-material-ids.cfg` and the enchantment and potion ids in `gtsr.cfg` and
  `GTNotLeisure/item.cfg` have to match the client. `GregTech.cfg` brings the client's
  `explosionItemDrop=true` [false], moot while machine explosions are off.
- New mods' files: `ae2wtx.cfg`, `benzenefuels.cfg`, `disk_terminal_server.cfg` (must
  match), `gtnh-modernization.cfg`, `structureterminal.cfg`, `laggoggles.cfg`,
  `patchee.cfg`, `thaumicdualityinterface.cfg`, `bqext.cfg`
- `betterquesting/DefaultQuests/`, which adds the Benzene Fuels and Processing Plus lines
- `omniminer/omniminer_server.cfg` at the server root, not in `config/`
- `scripts/gtnl_disable_vein_pickaxe.zs`, next to `simplestorage_gregified.zs`. Its
  assembler removal only takes on `minetweaker reload` after start. Omni Server sends it
  through the "MineTweaker reload" quick command with Run when the server has started on,
  and the `gtnh` launcher on its own (see [mods.md](./mods.md#scripts)).
- `config/ysmu/custom/`, mirrored from the client (45 models)

A test boot on 2026-11-19 (Java 25, 8G, world in a scratch folder) reached `Done` with
the synced set and stopped cleanly. WTCT logs ten `PACKAGE_TRANSFORMER_EXCLUSION` mixin
errors on both sides; they predate the sync. `start.sh`'s `JAVA` path and translation
agent path don't exist on eclipse; the laptop module sets its own.

Already matching and left alone: `EZNuclear.cfg`,
`ezstorage.cfg`, `gtnhrates.cfg`, `programmablehatches.cfg`, `NHUtilities/`,
`waystones.cfg`, `effortless.cfg`, `omnitweaks.cfg`, `EnderStorage.cfg`,
`structurelib.cfg`, `angermod.cfg`, `GregTech/{Pollution,WorldGeneration}.cfg`, Gendustry,
Forestry, LootGames, Iguana Tinker Tweaks and `OmniOcular/`. `TwistSpaceTechnology.cfg`
keeps the server's own 0.8.0 file: the client's carries leftover keys from the 0.8.2
trial (Mega Digester, Bottled Chaos). `DistantHorizons.toml` and `serverutilities/` are
server-specific and were not touched. `Omni Ocular Unofficial.cfg` needs
`gtnhConfigAutoUpdate=false`, or each start replaces the English `OmniOcular/` scripts
with Chinese ones (see [mods.md](./mods.md)).

## ServerUtilities

The client has a copy at `.minecraft/serverutilities/` for singleplayer and LAN worlds;
the server has its own. Apply the same edits to both, or the hosted world behaves
differently from a local one.

`serverutilities.cfg`:

- `B:chunk_claiming=true` [false]
- Under `commands`, all default `false`, set to `true`: `B:home`, `B:warp`, `B:rtp`,
  `B:spawn`, `B:tpa`. `B:back=false` turns `/back` off (since 2026-11-05).
- `ranks { B:enabled=true }` [true], `B:override_chat=false` [true] keeps plain chat. The
  `/home` timers can only be changed through ranks. With ranks off, a player gets the
  mod's built-in 5 s warmup and 5 minute cooldown (ServerUtilities 2.4.22).

`server/ranks.txt` needs the full `serverutilities.claims.max_chunks` key form. `[player]`
has `homes.warmup: 5s`, `homes.cooldown: 5s` and `homes.cross_dim: true` (`[admin]` has
cross-dimension homes too); claims 100, chunkloaders 50 and homes 1 match the built-in
player defaults. Every rank has a 5 s cooldown on `homes`, `warps`, `tpa`, `spawn`, `back`
and `rtp`; warmups other than `/home`'s keep the built-in values. These edits are on the
laptop's server copy; the old files are in `~/Documents/Minecraft_Servers/serverutilities-before-ranks-2026-11-05.tar.gz`.

## Waystones

- `config/waystones.cfg` → `xpBaseCost=-1` disables the XP cost. The file appears once
  the mod is installed.

## World

Generate a fresh world on the server and copy it nowhere. 2.9's terrain, ore mix and
CropsNH data only exist in worlds created under 2.9, and an old world keeps its 2.8
generation. The old 2.8.4 world is only in the laptop's server folder named at the top
of this page; the 2.8.4 client instance is gone from the desktop (checked 2026-11-04).
