# GTNH 2.9.0 Java & Launch

## Java

- The instance points at OpenJDK 25 (`/nix/store/6mjvrmphia72izv1qpm04j5fkvpqjbhy-openjdk-25.0.4.1+1/bin/java`,
  `JavaVersion=25.0.4.1`).
- 2.9.0 ships as a Java 17-26 pack. The [Installing and Migrating](https://wiki.gtnewhorizons.com/wiki/Installing_and_Migrating)
  page (read 2026-11-02) recommends Prism with **Java 25+** over everything else,
  calling 25 the most optimized and least memory-hungry runtime for GTNH, and notes that
  25 needs 2.8+ and 26 needs 2.9+.
- The same page suggests `-XX:+UseCompactObjectHeaders` on Java 25+. The instance sets it
  through `OverrideJavaArgs=true` and `JvmArgs=-XX:+UseCompactObjectHeaders`; the pack's
  own args come from the lwjgl3ify launchargs patch, not from that field.
- `modules/nixos/gaming/tools/java.nix` marks jdk21 `lowPrio`, so the profile's `java` is
  25 (25.0.5, checked 2026-11-04). The local server's `start.sh` doesn't use it: it pins
  the same 25.0.4.1 store path as the instance (override with `GTNH_JAVA=...`) and passes
  the same flag. The laptop module uses `pkgs.jdk25` and passes it too.

## JVM args

The 2.9 instance has `OverrideJavaArgs=true` with `-XX:+UseZGC`,
`-XX:SoftMaxHeapSize=11g`, `-XX:+UseCompactObjectHeaders` and the translation agent,
`-javaagent:` pointing at `.minecraft/gtnh-translation-agent.jar` (set 2026-11-07). An
instance's args replace Prism's global set rather than add to it (`OverrideJavaArgs` in
Prism's `MinecraftInstance.cpp`), so the Aikar-style G1 flags in `prismlauncher.cfg`
only reach the other instances. ZGC is generational-only on Java 25, so there is no
`-XX:+ZGenerational`; removing `-XX:+UseZGC` falls back to G1.

Memory is overridden too (`OverrideMemory=true`, 14336 MB min and max). A GC log from a
21-minute session on the laptop server at 12 GB (2026-11-07) showed a steady 5-6 GB live
set but five allocation stalls of 50-107 ms, when Angelica and Distant Horizons chunk
building filled the heap before ZGC caught up. The soft cap makes ZGC collect as if the
heap were 11 GB and keeps the last 3 GB for those bursts. An `Allocation Stall` line in a
GC log means the reserve ran out. With the local server on the desktop at the same time,
use 12 GB with `SoftMaxHeapSize=10g`. To log GC in a running client, use
`jcmd <pid> VM.log output=file=<path> what=gc,gc+heap=info decorators=uptime,level,tags`
with the instance's JDK.

The agent translates hard-coded Chinese strings in the hand-added mods. Its source, build
and the matching quest and lore data patches are in
`~/Documents/Minecraft_Servers/GTNH-Translation/`, with the steps in its `translations.md`.
It isn't in this repo. Updating one of those mods can bring back untranslated text. The
client's copy sits in `.minecraft/` because the Prism Launcher AppArmor profile denies
reading it from `~/Documents`, and the JVM then exits without writing a log.

The laptop's args live in `machines/legion/minecraft-servers/gtnh-server.nix`; the only
2.9 change there is `-XX:+UseCompactObjectHeaders`, and it doesn't load the agent yet. The
desktop's are in [server.md](./server.md#local-server-on-the-desktop).

## lwjgl3ify

- **Mouse:** `B:rawMouseInput=false` in `config/lwjgl3ify.cfg` [true].
- **Desktop entry:** `B:linuxCreateAppDesktopEntry=false` in `config/lwjgl3ify.cfg` [true].
  On first launch it writes `~/.local/share/applications/com.gtnewhorizons.Lwjgl3ifyMinecraft.desktop`,
  which the Prism Launcher AppArmor profile denies, and lwjgl3ify turns the refusal into a
  launch failure (`Could not follow linuxCreateAppDesktopEntry logic`). The file only sets
  a Wayland app-id.
- **SDL:** the 2.8.4 fix was `SDL_VIDEODRIVER=x11` in Prism's environment variables. That
  variable is not set in `prismlauncher.cfg` now (only `ALSOFT_DRIVERS` and the cursor
  variables), and 2.9 launches without it. If lwjgl3ify reports SDL failing to find a
  video driver, add it back.

## Renderer

`config/angelica-modules.cfg` has `S:renderBackend=OPENGL` at the moment. The
experimental `SDL_GPU` path (Vulkan) runs the game, but it cannot draw BetterCrashes'
startup error screen, so a mod init failure looks like a frozen loading screen. It was
not the cause of any startup failure. Switch it back in Video Settings once the pack is
settled.

## JourneyMap

2.9.0 ships `journeymap-1.7.10-5.2.23-fairplay.jar`, and the instance still runs it
(checked 2026-11-04): the 2.8.4 swap to the unlimited build has not been redone. To redo
it, in `.minecraft/mods/`:

1. Delete `journeymap-1.7.10-5.2.23-fairplay.jar`.
2. Add `5.2.23-unlimited`. It has to be the same JourneyMap version, so don't reuse the
   old `5.2.10` jar.
3. Delete `defaultserverlist-1.7.4.jar`, which only adds a pre-populated server list.
