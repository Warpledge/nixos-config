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
- The local server used to run the profile's `java`, which was 21 because jdk21 shadowed
  jdk25 in `environment.systemPackages`. `modules/nixos/gaming/tools/java.nix` now marks
  jdk21 `lowPrio`, so the next rebuild makes `java` 25; until then `start.sh` pins the
  JDK 25 path (override with `GTNH_JAVA=...`) and passes the same flag. The laptop module
  already used `pkgs.jdk25` and now passes it too.

## JVM args

The 2.9 instance has `OverrideJavaArgs=true` only to add `-XX:+UseCompactObjectHeaders`.
Everything else still comes from Prism's global set in `prismlauncher.cfg`: the
Aikar-style G1 flags and `MaxMemAlloc`/`MinMemAlloc` of 12288 MB.

The server's own args live in `machines/legion/minecraft-servers/gtnh-server.nix`; the only
2.9 change there is `-XX:+UseCompactObjectHeaders`.

## lwjgl3ify

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

2.9.0 ships `journeymap-1.7.10-5.2.23-fairplay.jar`. The unlimited swap still works, but
the replacement has to be the same JourneyMap version, so get `5.2.23-unlimited` rather
than reusing the old `5.2.10` jar. The swap steps are in
[the 2.8.4 note](../2.8.4/java-and-launch.md#journeymap--swap-fairplay-for-unlimited).
