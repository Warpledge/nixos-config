# Server — TerraFirmaGreg-Modern

## Setup

- **Server path:** `~/Documents/Minecraft_Servers/TerraFirmaGreg-Modern-0.12.5/`
- **Port:** 25566
- **Loader:** Forge 1.20.1-47.4.13
- **Java:** JDK 21
- **Script:** `hosts/laptop/minecraft-servers/tfg-server.nix` — defines `tfg` CLI

## tfg Command

```bash
tfg           # Start server (or attach to running tmux session)
tfg log       # Tail latest.log
tfg stop      # Send /stop to the running server
tfg status    # Check if session is running
```

Runs in a persistent tmux session named `terrafirmagreg-modern`. Auto-restarts on crash with a 12-second countdown. Clean shutdown (exit 0) stops the restart loop. Crashes are logged to `server_crashes.log`.

## One-Time Setup (first launch)

```bash
cd ~/Documents/Minecraft_Servers/TerraFirmaGreg-Modern-0.12.5
java -jar minecraft_server.jar nogui   # installs Forge, then exit
echo "eula=true" > eula.txt
```

## JVM Args

```
-Xms12288M -Xmx12288M
--add-modules=jdk.incubator.vector
-XX:+UseG1GC
-XX:+ParallelRefProcEnabled
-XX:MaxGCPauseMillis=200
-XX:+UnlockExperimentalVMOptions
-XX:+DisableExplicitGC
-XX:+AlwaysPreTouch
-XX:G1NewSizePercent=40
-XX:G1MaxNewSizePercent=50
-XX:G1HeapRegionSize=16M
-XX:G1ReservePercent=15
-XX:G1HeapWastePercent=5
-XX:G1MixedGCCountTarget=4
-XX:InitiatingHeapOccupancyPercent=15
-XX:G1MixedGCLiveThresholdPercent=90
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:SurvivorRatio=32
-XX:+PerfDisableSharedMem
-XX:MaxTenuringThreshold=1
-Dusing.aikars.flags=https://mcflags.emc.gs
-Daikars.new.flags=true
@libraries/net/minecraftforge/forge/1.20.1-47.4.13/unix_args.txt
nogui
```

Aikar's G1GC flags tuned for modded Forge servers (12 GB heap).

## server.properties

```properties
online-mode=false
difficulty=normal
max-players=10
server-port=25566
```

## Server-Side Mods

<!-- List any mods added/removed server-side only -->
