# GTNH 2.9.0

Client instance: `GT_New_Horizons_2.9.0_Java_17-26` (Prism Launcher)
Path: `~/.local/share/PrismLauncher/instances/GT_New_Horizons_2.9.0_Java_17-26/.minecraft/`

2.9.0 released 2026-10-31. This set covers a new world, not a migration from 2.8.4:
existing saves keep 2.8 world generation, so the new terrain only exists in a world
created under 2.9.

## Sub-Notes

- [mods.md](./mods.md): which hand-added mods carry over, which have a 2.9 build, and which are out
- [config-tweaks.md](./config-tweaks.md): every config edit, with 2.9 paths and defaults
- [java-and-launch.md](./java-and-launch.md): Java, Prism's JVM args, lwjgl3ify
- [shaders.md](./shaders.md): the NeonTech setup, Complementary Unbound with Euphoria Patches and Neon Horizons
- [server.md](./server.md): the desktop and laptop servers, their mods and the current world

The translation agent and data patches for the hand-added mods are outside this repo, in
`~/Documents/Minecraft_Servers/GTNH-Translation/`; see
[java-and-launch.md](./java-and-launch.md#jvm-args).

## Startup crashes in 2.9

Forge 1.7.10's log4j crashes while printing a mod's init failure. The report then shows
`NoClassDefFoundError: net/minecraft/inventory/ISidedInventory`, names Forge as the
suspect, and hides the real error. The culprit is the mod marked `UCHE` in the mod list
inside the same crash report. Twist and 123Technology both did this on 2.9.0 stable until
their PR builds (see [mods.md](./mods.md)).

## Performance

Carried from 2.8.4 and not retested on 2.9, where the renderer changed (Angelica 2.2.43,
Celeritas instead of Sodium 0.2). Distant Horizons notes are in [mods.md](./mods.md).

`wailaAverageNS=true` in `config/GregTech/Client.cfg` makes WAILA show a GT machine's CPU
time per tick, out of a 50,000,000 ns budget:

| Average | Reading |
| --- | --- |
| Under 10,000 ns | Normal |
| 10,000 to 50,000 ns | Slightly heavy |
| 50,000 to 500,000 ns | Laggy, investigate |
| Over 500,000 ns | Significant, fix first |

Multiblocks run higher than single blocks because of structure validation, so a high
value on an idle machine is structure-check overhead. Heavy I/O (AE2 interfaces, sorting,
void excess) tends to spike. For the whole game, run `/spark profiler` in the client;
Spark is not on the server, and LagGoggles is not installed on 2.9.

## Sources

- [Version 2.9.0](https://wiki.gtnewhorizons.com/wiki/Version_2.9.0)
- [Before you update](https://changelog.gtnh.ogricanx.ch/2.8.4_to_2.9.0/before-you-update.html)
- [Installing and Migrating](https://wiki.gtnewhorizons.com/wiki/Installing_and_Migrating)
