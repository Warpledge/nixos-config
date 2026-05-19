# Java & Launch Setup

## Java Runtime

- **Runtime:** OpenJDK 25 — installed via `pkgs.jdk25` in `shared/modules/nixos/programs/gaming/java.nix`
- GTNH recommends Java 25 for 2.8.x
- **JVM Arguments:** ZGC with full arg set — managed via `hosts/laptop/minecraft-servers/gtnh-server.nix`, not `startserver-java9.sh`
  - `-XX:+UseZGC -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem -XX:+UseTransparentHugePages`
  - Memory: `-Xms12G -Xmx12G`

## lwjgl3ify

- **Config:** `B:rawMouseInput=false` in `config/lwjgl3ify.cfg` (default: `true`)
- **SDL/Wayland fix:** On NixOS/Wayland, lwjgl3ify's bundled SDL can't find Wayland and crashes on launch. Fix: add `SDL_VIDEODRIVER=x11` as a global environment variable in Prism Settings → Environment Variables. This forces SDL to use XWayland (DISPLAY=:0).

## JourneyMap — Swap Fairplay for Unlimited

The pack ships with `journeymap-...-fairplay.jar`. Replace it with the `unlimited` variant (same version):
1. Delete `journeymap-...-fairplay.jar` from `.minecraft/mods/`
2. Drop in `journeymap-...-unlimited.jar`
3. Delete the `defaultserverlist` mod jar from `.minecraft/mods/` (adds a pre-populated server list, not needed)
