# GTO 0.6.0 Java & Launch

## Java

The instance runs `/run/current-system/sw/bin/java`, the system's OpenJDK 25 (25.0.5 on
2026-11-07), like the GTNH instances; [GTNH's notes](../../GTNH/2.9.0/java-and-launch.md#java)
say why it's the link and not a `/nix/store` path. The 0.6 guide supports Java 21, 25
and 26 and recommends 25. Prism's Java compatibility check is skipped for the instance.

## JVM args

`OverrideJavaArgs=true` with `-XX:+UseZGC -XX:SoftMaxHeapSize=10g
-XX:+UseCompactObjectHeaders`. These replace Prism's global args instead of adding to
them.

Memory isn't overridden in the instance, so it takes Prism's global 12288 MB min and max
from `prismlauncher.cfg`. 12 GB is an estimate carried from 0.5.6, not measured. To
check it, log GC in the running client with the instance's JDK:

```bash
jcmd <pid> VM.log output=file=<path> what=gc,gc+heap=info decorators=uptime,level,tags
```

`Allocation Stall` lines mean the heap is too small for that session.

## Sources

- [0.6 guide](https://gtodyssey.com/articles/en/c1f8b283-dbe1-433f-aaaf-ec023e90379f)
- `instance.cfg` and `prismlauncher.cfg`, read 2026-11-07
