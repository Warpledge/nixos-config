# GTO's Mixins

0.6.0-dev27, read 2026-11-12. gtocore's jar holds two mixin configs:
`gtocore.mixins.json` (package `com.gtocore.mixin`, source public) and
`gtolib.mixins.json` (`com.gtolib.mixin`, decompiles but calls sealed code). Both are
`"required": true`. `gto.py map` prints every target class; this note says what the
groups do and which matter when adding a mod.

## Counts by target

| Target | Mixins | Classes | Of which exclusive |
| --- | --- | --- | --- |
| Minecraft | 106 | 84 | 43 |
| AE2 (fork) | 73 | 70 | 28 |
| GregTech Modern (fork) | 57 | 56 | 28 |
| EMI (fork) | 23 | 18 | 10 |
| Ad Astra | 22 | 22 | 16 |
| LDLib | 15 | 14 | 10 |
| ExtendedAE (fork) | 12 | 12 | 4 |
| Forge | 11 | 11 | 7 |
| Apotheosis | 10 | 10 | 6 |
| 40 other mods | 1 to 6 each | | |

"Exclusive" counts the mixins using `@Overwrite`, `@Redirect` or `@ModifyConstant`,
which replace code rather than add to it; the totals come from `gto.py map`. 149 classes GTO patches are also patched by another
installed mod; `map` lists them.

## Config plugins

`com.gtocore.config.MixinConfigPlugin` skips the gtocore mixins for Balm, Xaero's
minimap and world map, More Red, Inventory Essentials, FTB XMod Compat, Render Blender,
Corpse, Mouse Tweaks and some Sophisticated Core and Backpacks mixins when those mods
are absent. Every other mixin always applies, so removing a pack mod GTO mixes into
(Apotheosis, Patchouli, Jade, FTB Quests, Farmer's Delight and so on) fails at mixin
apply. gtolib has its own plugin, `com.gtolib.MixinConfigPlugin`, which is sealed.

## Hot spots for add-ons

### Resource loading and caches

- **Tags:** gtolib `TagLoaderMixin` overwrites `TagLoader.load` at priority 2000. It
  reads tag files through `GTOTags.load` and, with `misc.cacheResources: true` in
  `config/gtocore.yaml` (the default), keeps them in an on-disk cache between launches.
  A mod's own `TagLoader` mixin may fail to inject into the overwritten method (Moog's
  Structure Lib 3.3.0+ does, see [../mods.md](../mods.md)). GTOTags also drops tag entries after
  `morered:red_alloy_ingot` in a tag file and AE2's legacy tiered interface IDs.
- **Loot tables:** gtolib `LootDataManagerMixin` builds the loot table map once per
  game session (`GTOLoots.cache`) and hands back the same map on every reload, so
  **`/reload` never picks up a loot table change**; restart the game. It adds GTO's
  dynamic loot and Placebo's tables to the map. `LootTableMixin` redirects Forge's
  global loot modifier call through GTO code.
- **Recipes:** gtolib `RecipeManagerMixin` cancels `RecipeManager.apply` and
  `replaceRecipes` and runs sealed code instead. Datapack recipes still load (the
  `warpledge-gto` datapack works through it), but the order and error handling are
  GTO's. `IngredientMixin` overwrites `Ingredient.getItems` and `test`;
  `ClientboundUpdateRecipesPacketMixin` changes how recipes go to clients.
- **JSON reload listeners:** `SimpleJsonResourceReloadListenerMixin` overwrites the
  shared directory scan every JSON reload listener uses (recipes, advancements, loot
  modifiers and most mods' data). The `pack.*` mixins swap Minecraft's and Forge's pack
  resources for GTO's faster file access.
- **Registries:** overwrites on `ResourceLocation` (`equals`, `hashCode`, `toString`,
  path checks), `Holder.Reference.bindTags`, `DependencySorter`, `ForgeRegistry`,
  `NamespacedWrapper` and `RegistryObject`. A mod mixing into these gets GTO's code.

### EMI and JEI

GTO overwrites EMI's plugin discovery (`EmiForgePlatform.getPlugins`, gtolib
`EmiAgnosMixin`) and JEI's (`ForgePluginFinder.getModPlugins`, gtocore
`ForgePluginFinderMixin`). Both return only what `GTEMIPlugin` registers:

- EMI: vanilla, EMI Trades, Sophisticated Backpacks and Storage, Botania, ExtraBotany,
  LDLib, GTM, Ars Meteorites, AE2, ExtendedAE, Farmer's Delight, EMI Loot.
- JEI (shown through EMI's JEMI bridge): JEI's own, Apotheosis' four, Just Enough
  Resources, Mythic Botany, Farmer's Respite, Ars Nouveau, Jade, plus FTB XMod Compat
  and Calculator Overlay when installed.

Any other mod's EMI or JEI plugin is skipped unless its class name goes in
`misc.enableEmiJeiExternalPlugins` in `config/gtocore.yaml` (a YAML list, empty in
dev27), for example `- com.simibubi.create.compat.jei.CreateJEI`. Find a mod's plugin
class with `unzip -l <jar> | grep -iE 'emi|jei'` and look for the class implementing
`EmiPlugin` or annotated `@JeiPlugin`. `gtocore.yaml` isn't in `overlay.json`'s carried
files, so a change there has to be carried by hand to a new build.

EMI's stack list bake (`EmiStackList`) is overwritten too; mods that hide or add stacks
through mixins there rather than the plugin API lose them.

### GTM addons

gtolib `AddonFinderMixin` overwrites `AddonFinder.getAddons`, GTM's scan for `@GTAddon`
classes, with a list built in sealed gtolib code. No dev27 jar has a `@GTAddon` class,
so whether a new GTM addon's materials, machines and recipes load is untested; assume
they don't until a staging run shows them in EMI.

### World and chunk ticking

- gtolib `ServerChunkCacheMixin`: chunks tick (natural spawning and random ticks) on
  1 server tick in 10, offset randomly per dimension; in void dimensions 1 in 200 with
  mob spawning off. `randomTickSpeed` is fixed at 30 (600 in void), so the gamerule does
  nothing; 30 every 10 ticks equals vanilla's 3 per tick, but natural spawn cycles run
  a tenth as often as vanilla's. On ticks with time to spare, `ChunkMapMixin` runs part
  of `ChunkMap.tick` only every 80th tick.
- `ServerLevelMixin` reports entity ticking off everywhere in void dimensions.
- `OreConfigurationMixin` strips vanilla ore blocks from every `OreConfiguration`
  feature at construction, any mod's included. A mod whose ore feature targets vanilla
  ores generates nothing for them; its own ore blocks are unaffected.
- `LevelMixin` dims daylight for the Dyson sphere; `ServerLevelWeatherMixin` adds a
  solar storm to the weather cycle; `MinecraftServerMixin` stops time sync in locked
  void worlds.

### Entities and mobs

- gtocore `MobMixin` (rule `survival.mob_enhancement`, on except under Easy): random
  extra health and damage on half of mobs and all bosses, and changes despawn checks.
  `AbstractSkeletonMixin` changes skeleton arrows.
- gtolib `MonsterMixin` makes monster spawn light checks read Hard difficulty.
- gtolib `BatMixin` deletes every bat on its first tick; `GlowSquidMixin` stops glow
  squid spawning and deletes existing ones. A mod that spawns or depends on bats or
  glow squids (as mounts, drops or spawn eggs) loses them.
- `EnderManMixin` hooks teleporting; `EntityMixin` changes pushing and entity
  collisions; the two `ItemEntityMixin`s add extra item count stacking and change item
  entity ticking and merging.
- `PlayerMixin`, `ServerPlayerMixin`, `FoodDataMixin` and `LivingEntityMixin`: flight,
  food level, exhaustion scaling, respiration, damage scaling and permission level.

### Items

gtolib `ItemStackMixin` overwrites `isEmpty`, `getItem`, `getCount`, `shrink`, `save`,
`isSameItem` and Forge's init, and redirects the constructors. `ItemMixin` overwrites
`toString`. Mods mixing into ItemStack's core methods (inventory sorters, stack size
mods) are the likeliest to clash. `CompoundTagMixin` overwrites `sizeInBytes`.

### Ad Astra

gtolib overwrites Ad Astra's `GravityApiImpl`, `OxygenApiImpl`,
`TemperatureApiImpl`, `PlanetApiImpl`, `AdAstraData` and `ModUtils`. An Ad Astra add-on
that reads or sets gravity, oxygen or temperature through the API gets GTO's answers.
GTO's own planets are in [content.md](./content.md).

### Apotheosis and Placebo

Mixins on the adventure module, affix registry, bosses, loot rarity, and the Earth's
Boon, Miner's Fervor and Capturing enchantments. Placebo's Patreon preview tick is
emptied and its wings and trails managers overwritten. Add-ons for Apotheosis affixes or gems should be tried in staging.

## Other groups

- **AE2 (73):** patterns (10 classes: crafting, processing, smithing and stonecutting
  patterns and their encoding), the grid and its nodes, crafting CPU and service, cells,
  storage bus, IO port, pattern provider and its terminal, terminals and screens, and
  AE2's EMI module. Add-ons that extend patterns, crafting CPUs or the pattern provider
  touch the most-patched code.
- **GTM (57):** registration (`GTBlocks`, `GTFluids`, `GTMaterialItems`, `GTOres`,
  `GTRecipeTypes`, `GTMultiMachines`), `Material` and `TagPrefix`, machine bases, and
  maintenance, energy, muffler and data hatches. GTO's materials and machines are
  registered through these.
- **LDLib (15), Forge (11):** UI widgets, baked models, fluid stacks and item handlers.
- **Quest, map and QoL mods:** FTB Quests, FTB Ultimine, FTB XMod Compat, Xaero's World
  Map, Inventory Essentials, ME Requester, Building Gadgets 2, Patchouli, Jade, Oculus,
  ModernFix, FerriteCore, Embeddium, Open Parties and Claims and others, 1 to 6 each.
- **Drone:** 18 `Drone*` mixins across Minecraft, GTM and Jade for GTO's drone
  camera.

## Sources

- `gto.py map` on the dev27 instance; mixin classes decompiled with CFR 0.152
- GTOCore-Main `0.6.0`: `com/gtocore/config/MixinConfigPlugin.java`,
  `com/gtocore/common/data/GTOLoots.java`, `GTOTags.java`,
  `com/gtocore/integration/emi/GTEMIPlugin.java`,
  `com/gtocore/mixin/jei/ForgePluginFinderMixin.java`, read 2026-11-12
- `config/gtocore.yaml` comments for `cacheResources` and `enableEmiJeiExternalPlugins`
