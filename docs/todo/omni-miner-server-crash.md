# Fix Omni Miner's Block Swap crash on dedicated servers

**Goal:** stop Omni Miner's Block Swap from crashing legion's GTNH 2.9.0 server, and catch any other client-only calls in the fork before a player triggers them. Done on eclipse, where the fork's source is.

Added 2026-11-21.

## What happened

On 2026-11-21 at 20:54 a player used Block Swap on a torch and legion's server crashed with "Exception in server tick loop" (`crash-reports/crash-2026-11-21_20.54.46-server.txt` in `~/Documents/Minecraft_Servers/GT_New_Horizons_2.9.0_Server_Modified/`):

```
java.lang.NoSuchMethodError: 'net.minecraft.util.MovingObjectPosition net.minecraft.entity.player.EntityPlayerMP.func_70614_a(double, float)'
  at com.czqwq.EZMiner.core.Manager.onBlockSwapRightClick(Manager.java:200)
  ... ForgeEventFactory.onPlayerInteract <- NetHandlerPlayServer (C08PacketPlayerBlockPlacement)
```

`func_70614_a` is `EntityLivingBase.rayTrace`, which is `@SideOnly(Side.CLIENT)` and stripped from the dedicated server. Any Block Swap use crashes the server; the block doesn't matter. Single player hides it, because the integrated server has the client classes. The server runs `omniminer-6.6-balanced.13.jar`.

**Until it's fixed:** don't use Block Swap on the server, or turn it off under `features { }` in `omniminer_server.cfg` at the instance root and restart the server.

## What's already in the repo

- `docs/personal/gaming/minecraft_servers/GTNH/2.9.0/mods.md`: the Omni Miner row (`6.6-balanced.13`) and its notes.
- `docs/personal/gaming/minecraft_servers/GTNH/2.9.0/config-tweaks.md`: the Omni Miner config row, which names the version.
- `docs/personal/gaming/minecraft_servers/GTNH/2.9.0/mod-sources.json`: the Omni Miner entry (`local:~/Projects/ezminer-balanced`).

## Steps

1. In `~/Projects/ezminer-balanced` on eclipse, replace the `rayTrace` call in `Manager.onBlockSwapRightClick` with a raytrace both sides have: eye at `player.posY + player.getEyeHeight()`, direction `player.getLook(1.0F)`, reach from `((EntityPlayerMP) player).theItemInWorldManager.getBlockReachDistance()`, then `world.rayTraceBlocks(eye, end, false)`. Put it in a shared helper if other code raytraces too. Block Swap's behaviour stays the same otherwise.
2. Search the fork for other client-only use reachable from server-side code (event handlers, packet handlers, common code): `rayTrace(`, `func_70614_a`, `Minecraft.getMinecraft`, `net.minecraft.client.*`, and `@SideOnly(Side.CLIENT)` methods or fields on `Entity`, `World`, `Item` and `Block`. Fix the ones on a server path.
3. Bump to `6.6-balanced.14` and build.
4. Test Block Swap on a real dedicated server (legion's, or a local `nogui` one), not single player.
5. Put the jar in legion's server `mods/` and the client instance, replacing `.13`.
6. Update the Omni Miner rows in `mods.md` and `config-tweaks.md`, then delete this note.

## Also check

After the crash, each automatic restart (20:54:50, 20:57:38, 20:59:29) got a `stop` over RCON from 127.0.0.1 about 10 s after `Done`, and the server shut down cleanly. The server has no scheduled restart, and its only on-start quick command is `minetweaker reload`. The source wasn't found on 2026-11-21; if a start-then-stop cycle shows up again without anyone pressing Stop or Restart, look at what connects over RCON at that moment (the monitor, the Omni Server window, or a mod).
