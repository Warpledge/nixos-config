# GTNH 2.9.0

Client instance: `GT_New_Horizons_2.9.0_Java_17-26` (Prism Launcher)
Path: `~/.local/share/PrismLauncher/instances/GT_New_Horizons_2.9.0_Java_17-26/.minecraft/`

2.9.0 released 2026-10-31. This set covers a new world, not a migration from 2.8.4:
existing saves keep 2.8 world generation, so the new terrain only exists in a world
created under 2.9. The 2.8.4 notes are at `../2.8.4/` for anything that is still the
same.

## Sub-Notes

- [mods.md](./mods.md): which hand-added mods carry over, which have a 2.9 build, and which are out
- [config-tweaks.md](./config-tweaks.md): every config edit, with 2.9 paths and defaults
- [java-and-launch.md](./java-and-launch.md): Java, Prism's JVM args, lwjgl3ify
- [shaders.md](./shaders.md): the NeonTech setup, Complementary Unbound with Euphoria Patches and Neon Horizons
- [server.md](./server.md): the laptop server build and what changes in its NixOS module

## Not written yet

Performance profiling still lives in the 2.8.4 set and has not been retested against
2.9. The renderer changed (Angelica 2.2.43, Celeritas instead of Sodium 0.2), so treat
[performance.md](../2.8.4/performance.md) as a starting point only. Distant Horizons
notes are in [mods.md](./mods.md).

## Sources

- [Version 2.9.0](https://wiki.gtnewhorizons.com/wiki/Version_2.9.0)
- [Before you update](https://changelog.gtnh.ogricanx.ch/2.8.4_to_2.9.0/before-you-update.html)
- [Installing and Migrating](https://wiki.gtnewhorizons.com/wiki/Installing_and_Migrating)
