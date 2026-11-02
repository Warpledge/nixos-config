# GTNH 2.9.0 Java & Launch

## Java

- The instance points at OpenJDK 25 (`/nix/store/6mjvrmphia72izv1qpm04j5fkvpqjbhy-openjdk-25.0.4.1+1/bin/java`,
  `JavaVersion=25.0.4.1`).
- 2.9.0 ships as a Java 17-26 pack. The wiki says Java 25 from 2.8 and Java 26 from
  2.9, so 25 is inside the supported range; the server module already uses `jdk25`.

## JVM args

The 2.9 instance has `OverrideJavaArgs=false`, so it uses Prism's global set in
`prismlauncher.cfg`: the Aikar-style G1 flags and `MaxMemAlloc`/`MinMemAlloc` of 12288 MB.
Nothing per-instance to maintain.

The server's own args live in `machines/legion/minecraft-servers/gtnh-server.nix` and are
unchanged by 2.9.

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
