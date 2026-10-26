---
name: tmodloader-workflow
description: Which tModLoader version a Terraria mod targets, what changed in 1.4.5 that 1.4.4 code gets wrong, and how to build a mod and read its logs on this NixOS machine. Use together with the tmodloader skill whenever writing, porting, building or debugging a tModLoader mod.
---

# tModLoader workflow

The `tmodloader` skill has the API templates. This one covers the version and the
build, which decide whether that code compiles.

## Which version first

tModLoader 1.4.5 (Terraria 1.4.5, versions v2026.xx) breaks 1.4.4 mods; neither runs
the other's. Before writing hook code, find out which one the mod is built against:

- Ask, if it isn't clear, which Steam branch Ky plays (stable, preview, or a
  `1.4.4` legacy branch).
- Errors about `WorldItem`, `NPC.Spawner`, `Projectile.drawLayer` or `.NET 10` mean
  1.4.5; errors about missing `NPCSpawnInfo` or `DrawBehind` mean 1.4.4 code on 1.4.5.

Hook signatures differ between the two, so check the class page in the docs before
writing an override you aren't sure of:
`https://docs.tmodloader.net/docs/stable/class_<snake_case_name>.html` (`ModItem` is
`class_mod_item.html`, `ModNPC` is `class_mod_n_p_c.html`).

## 1.4.4 code that breaks on 1.4.5

From tModLoader's `MigrationGuide_1.4.5.md`. For a whole mod, run tModPorter first
(Develop Mods menu), then fix the `tModPorter` comments it leaves.

| 1.4.4 | 1.4.5 |
| --- | --- |
| Items in the world are `Item` (`Main.item`, `Item.position`) | They're `WorldItem`, wrapping the `Item` (`worldItem.inner`); in-world hooks get a `WorldItem item` parameter, so use `item.position`, not `Item.position` |
| `Item.NewItem(source, rect / x, y, w, h, ..., noBroadcast)` | `Item.NewItem(source, center, ...)` with `NewItemOwnership`, `velocity`, `modifier`; from a client use `Item.RequestNewItem`, or `player.QuickSpawnItem` |
| `ModNPC.SpawnChance(NPCSpawnInfo spawnInfo)` | `SpawnChance(NPC.Spawner spawner)`; `spawnInfo.Water` is `spawner.waterTile`, `PlayerSafe` is `noWorms`, `Sky` is `skyMob`; use `spawner` flags, not `Player.ZoneX` |
| `DrawBehind`, `Projectile.hide` for held projectiles | `Projectile.drawLayer = ProjectileDrawLayerID.HeldProj` (and `usesOwnerLight = true` if held in hand) in `SetDefaults` |
| `PreDraw(ref Color lightColor)` using `Main.player[Projectile.owner]` | the new `Player` parameter on `PreDraw`/`PostDraw`/`PreDrawExtras` |
| `SetChatButtons`, `OnChatButtonClicked(bool firstButton, ref string shop)` | `RegisterChatButtons(NPCInteractionList)`, `OnChatButtonClicked(NPCInteraction)` |
| `TooltipLine.OverrideColor`, `IsModifier` | `TooltipLine.Color` (not nullable); compare with `Colors.PrefixGood`/`PrefixBad` |
| `Projectile.identity`, `projUUID` | `Projectile.key` |
| `Item.maxStack` defaults to 1 | defaults to 9999 (`Item.CommonMaxStack`); set `maxStack = 1` for weapons and tools if needed |
| sapling growth in `ModTile.RandomUpdate` | `ModTile.GrowSapling` |
| `ModPlayer.ModifyZoom` checking right mouse | `needsMouseRight` parameter; drop the mouse check |

Crafting-station tiles also need `TileID.Sets.HasOutlines[Type] = true`, a
`<TileName>_Highlight.png` texture and an `AddMapEntry` call.

## Mistakes in any version

- Spawning NPCs, items or world changes on a multiplayer client. Guard with
  `if (Main.netMode != NetmodeID.MultiplayerClient)`. `NPC.netUpdate = true` asks for
  a sync; it isn't a guard.
- Spawning a projectile on every client. Spawn it only for the owner
  (`if (Main.myPlayer == Projectile.owner)` or `player.whoAmI == Main.myPlayer`).
- Writing `DisplayName`/`Tooltip` in code. Text lives in `Localization/en-US.hjson`
  (or `en-US_Mods.<ModName>.hjson`), and tModLoader adds missing keys to it when the mod loads.
- A texture that isn't beside the class with the same name. `Items/MyItem.cs` needs
  `Items/MyItem.png`, or override `Texture`.
- Reading `Main.LocalPlayer` or drawing on a dedicated server. Guard with
  `!Main.dedServ`.

## Build and logs on this machine

tModLoader isn't packaged in this NixOS config; Ky installs it through Steam.

- Mod sources: `~/.local/share/Terraria/tModLoader/ModSources/<ModName>/`, the same
  folder for stable and preview. Each `.csproj` imports `..\tModLoader.targets`, which
  tModLoader writes into `ModSources/`.
- Build in game: Workshop > Develop Mods > Build. From a terminal, in the mod's folder:

  ```bash
  nix shell nixpkgs#dotnet-sdk_10 --command dotnet build
  ```

  1.4.5 needs the .NET 10 SDK, 1.4.4 the .NET 8 one (`dotnet-sdk_8`). Fix compile
  errors before asking Ky to test in game.
- Logs: `tModLoader-Logs/client.log` (and `server.log`) in the install folder,
  `~/.local/share/Steam/steamapps/common/tModLoader/tModLoader-Logs/`. Read the end of
  `client.log` after a crash or a failed mod load; exceptions name the mod and the
  method.
