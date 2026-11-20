# GTO 0.6.0 Java & Launch

## Java

The instance runs `/run/current-system/sw/bin/java`, the system's OpenJDK 25 (25.0.5 on
2026-11-07), like the GTNH instances; [GTNH's notes](../../GTNH/2.9.0/java-and-launch.md#java)
say why it's the link and not a `/nix/store` path. The 0.6 guide supports Java 21, 25
and 26 and recommends 25. Prism's Java compatibility check is skipped for the instance.

## JVM args

`OverrideJavaArgs=true` with `-XX:+UseZGC -XX:SoftMaxHeapSize=10g
-XX:+UseCompactObjectHeaders` (10g in dev27 and dev33's `instance.cfg`, checked
2026-11-20). These replace Prism's global args instead of adding to them.

The instance overrides memory (`OverrideMemory=true`) with 4096 MB min and 10240 MB max:
staging since 2026-11-14, Dev 33 since 2026-11-20 (dev27's main never got it).
Prism's global 12288 MB for both meant ZGC committed all 12 GB at launch and never gave
it back, so RSS sat at 16-17 GB. Measured that day in staging, with `jcmd` histograms after a full GC: about 2.6 GB live heap at the title screen and
4.8 GB in a world, plus about 3 GB native (direct buffers, GPU driver, metaspace). Yes
Steve Model loads every model in `config/yes_steve_model/custom/` into the heap, about
800 MB for 80 models. Main and staging now keep only the 45 starred ones; copies of
those and the star list (`starred.txt`) are in the gitignored
`minecraft_servers/ysm-backup/`. To check the heap size, log GC in the running client with the
instance's JDK:

```bash
jcmd <pid> VM.log output=file=<path> what=gc,gc+heap=info decorators=uptime,level,tags
```

`Allocation Stall` lines mean the heap is too small for that session.

## Sources

- [0.6 guide](https://gtodyssey.com/articles/en/c1f8b283-dbe1-433f-aaaf-ec023e90379f)
- `instance.cfg` and `prismlauncher.cfg`, read 2026-11-07
- `jcmd` `GC.heap_info`, `GC.class_histogram` and `VM.native_memory summary` on the
  staging client, 2026-11-14
