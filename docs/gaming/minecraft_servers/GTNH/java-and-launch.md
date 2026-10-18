# Java & Launch Setup

## Java Runtime

- **Runtime:** OpenJDK 25, called as `${pkgs.jdk25}/bin/java` in `machines/legion/minecraft-servers/gtnh-server.nix`. A bare `java` on PATH is JDK 21 (checked 2026-10-18): `modules/nixos/gaming/tools/java.nix` installs both, and JDK 21's `bin/java` wins the collision
- GTNH recommends Java 25 for 2.8.x
- **JVM Arguments:** Aikar-style G1 set, managed via `machines/legion/minecraft-servers/gtnh-server.nix`, not `startserver-java9.sh`
  - `-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem -XX:+UseTransparentHugePages` plus the G1 sizing flags in the module
  - Memory: `-Xms10G -Xmx12G`

## lwjgl3ify

- **Config:** `B:rawMouseInput=false` in `config/lwjgl3ify.cfg` (default: `true`)
- **SDL/Wayland fix:** On NixOS/Wayland, lwjgl3ify's bundled SDL can't find Wayland and crashes on launch. Fix: add `SDL_VIDEODRIVER=x11` as a global environment variable in Prism Settings → Environment Variables. This forces SDL to use XWayland (DISPLAY=:0).

## JourneyMap — Swap Fairplay for Unlimited

The pack ships with `journeymap-...-fairplay.jar`. Replace it with the `unlimited` variant (same version):
1. Delete `journeymap-...-fairplay.jar` from `.minecraft/mods/`
2. Drop in `journeymap-...-unlimited.jar`
3. Delete the `defaultserverlist` mod jar from `.minecraft/mods/` (adds a pre-populated server list, not needed)
