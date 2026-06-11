# Server Setup

**Instance:** `GT_New_Horizons_2.8.4_Java_17-25` server pack
**Host:** Laptop (Ryzen 7735HS), NixOS, Niri WM
**Port:** `25566` (non-default — desktop client connects via LAN)
**Java:** OpenJDK 25, ZGC (`-XX:+UseZGC`)

## server.properties

- `server-port=25566`
- `view-distance=8`
- `max-tick-time=0` — prevents watchdog crash during heavy world gen / large automation ticks

## Server Mods (Manual Additions)

Mods added on top of the base server pack. All listed mods go on **both server and client** unless noted.

| Mod | Version | Notes |
|---|---|---|
| EZMiner | 1.7+2.8.0 | Chain/blast mining — server-side block breaking |
| SharedProspecting | 2.0.4 | Syncs VisualProspecting ore data |
| BoxPlusPlus | 2.1.2 | LuV-tier production line encapsulator multiblock |
| GT: Not Leisure (GTNL) | 0.2.4 | Endgame content expansion — jar named `sciencenotleisure` |
| Twist Space Technology | 2.1.8+2.8.4 | Late-game content expansion |
| 123Technology | 1.0 | Late-game content expansion — installed as `OTHTechnology.jar` |
| EZNuclear | 1.0.7+2.8.0 | Prevents nuclear reactor explosions (configurable) |
| AE2Things | v1.2.14 | DISK cells, Infinity Cell, wireless terminals |
| NH-Utilities | 1.6.4 | Lunchbox Plus, Time Vial, NEI improvements |
| Programmable Hatches | 0.1.3p55 | Auto circuit management on multiblocks |
| GTNHRates | 1.8.1-2.8.4 | Energy/time discount, ore/crop/bee yield multipliers |
| ElytraMining | 1.7.10-1.2.0 | Hammers + falling torches |
| LagGoggles Legacy | 4.17.0 | In-world TileEntity tick profiler |
| FalsePatternLib | 1.10.7 | Dependency of LagGoggles |
| EZStorage | 1.6.0 | Early-game storage network |
| lwjgl3ify | 3.0.15 | Updated to pre-release — required for mod compatibility |
| GTNHLib | 0.9.47 | Updated to pre-release — required for mod compatibility |
| Spark | 1.10.19 | TPS/latency profiler |
| BetterSprinting | 1.1.3 | Sprint toggle and speed boost mechanics |
| deconfigintegration | 1.0.2 | In-game configuration GUI utility |
| Trash Slot | 1.0.31 | Void inventory slot for automation cleanup |
