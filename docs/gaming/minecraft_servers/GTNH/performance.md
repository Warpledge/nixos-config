# Performance & Lag Debugging

## WAILA Average NS — Interpreting Machine Lag Data

WAILA can display the average CPU load of GregTech machines in **nanoseconds (ns)** per tick. Enable via `config/GregTech/Client.cfg` → `wailaAverageNS=true` (NHUtilities also has `enableAlwaysDisplayWailaAverageNS=true` which requires the Client.cfg flag to actually work).

**What it means:** Each game tick has a budget of 50,000,000 ns (50ms). The NS value is how much CPU time that machine consumes per tick.

**Thresholds:**
| NS Range | Status |
|---|---|
| `< 10,000 ns` | Normal, no concern |
| `10,000 – 50,000 ns` | Slightly heavy, worth noting |
| `50,000 – 500,000 ns` | Laggy, investigate (multiblocks, complex fluid handling) |
| `> 500,000 ns` | Significant lag source, prioritize |

**Tips:**
- Point WAILA at machines when TPS drops to identify culprits
- Multiblocks run higher than single blocks due to structure validation
- High NS on a non-running machine = structure check overhead
- Machines with heavy I/O (AE2 interfaces, sorting, void excess) tend to spike
- For broader lag investigation, use **LagGoggles** for a visual overlay — more ergonomic than checking blocks one at a time

## Tools

- **LagGoggles Legacy** — Color-codes TileEntities in-world by tick time. Point at any machine to see per-block lag contribution. See [mods.md](mods.md#laggoggles-legacy) for install info.
- **Spark** — Global TPS/latency profiler. Run `/spark profiler` in-game to capture a flame graph. See [mods.md](mods.md#spark) for install info.
