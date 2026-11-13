# Checking a New Mod Against GTO

Run before a mod goes into staging, then trial it as in
[../updating.md](../updating.md#a-mod-trial). Written 2026-11-12 for 0.6.0-dev27; the
facts behind each step are in the other notes in this folder.

## Steps

1. Check the jar offline, with every library it needs downloaded beside it:

   ```bash
   python3 -I ../../tools/gto.py map GregTech.Odyssey-0.6.0-dev27 --mod ~/Downloads/<mod>.jar
   ```

   Lines with `!` are blockers or need a decision; `~` lines are mixins into code GTO
   owns, forks or patches; `?` lines target a mod the pack lacks (usually optional
   compat). Pass each library with its own `--mod`.
2. **A ModLauncher service** (`! ... registers ModLauncher service`): the game stops
   before a crash report, because `gto_native` refuses unknown services. Look for an
   older plain jar (Maid Spell 1.8.0.1, [../mods.md](../mods.md)).
3. **A dependency on a GTO fork** (GTM, AE2, ExtendedAE, EMI, Botania, Ars Nouveau):
   its version check passes against the date-based fork versions whatever API it was
   built for. Trial it, and expect `NoSuchMethodError` or `NoClassDefFoundError` in the
   log if the fork changed that API ([jars-and-forks.md](./jars-and-forks.md#forks)).
4. **`~` mixins marked `[Overwrite]`, `[Redirect]` or `[ModifyConstant]`** on a class
   GTO also patches: the two can't both win. Look the class up in
   [mixins.md](./mixins.md); `TagLoader`, `RecipeManager`, `Ingredient`, `ItemStack`,
   `ResourceLocation`, `LootDataManager`, `EmiStackList` and the Ad Astra API impls are
   GTO overwrites, so a mixin there either fails to apply (and crashes, if its config
   is required) or never runs. Moog's Structure Lib 3.3.0+ and its `TagLoaderMixin` is
   the known case.
5. **EMI or JEI integration:** the mod's plugin won't load on its own. Find its class
   ([mixins.md](./mixins.md#emi-and-jei)) and add it under
   `misc.enableEmiJeiExternalPlugins` in `config/gtocore.yaml`, which `gto carry`
   copies to new builds. GTO loads each listed
   class with `Class.forName` while mods are still being constructed, so a plugin whose
   static fields call into its mod's main class kills that mod: Youkai's `YHJeiPlugin`
   failed this way on 2026-11-12 (`NoClassDefFoundError: Could not initialize class
   ...YoukaisHomecoming`). Check the plugin's static fields first. Test that EMI still
   bakes with it on: a plugin or mod that breaks the bake takes EMI down for everything
   (Quark, and Alex's Mobs' brewing; see [../candidates.md](../candidates.md) and
   [../mods.md](../mods.md)). When it breaks, build
   [emiguard](../../tools/emiguard/README.md) into staging: it names a malformed recipe
   and dumps EMI's input for a with/without diff.
6. **Brewing recipes:** a mod that adds Forge `BrewingRecipe`s can give two recipes the
   same EMI id, which stops EMI's bake. Alex's Mobs needed
   [classpatch.py](../../tools/classpatch.py).
7. **GTM addon:** GTO replaces GTM's addon discovery, so assume its materials and
   machines won't appear until staging shows them in EMI
   ([mixins.md](./mixins.md#gtm-addons)).
8. **Worldgen:** ore features that place vanilla ores generate nothing for them (GTO
   strips vanilla ores from every ore feature). Structures go through
   [../structure-spacing.md](../structure-spacing.md). Loot tables load once per game
   session, so test loot changes after a restart, never after `/reload`.
9. **Mobs:** natural spawning is attempted on every 10th tick, monsters use Hard light
   rules, half of mobs get extra health and damage, and bats and glow squids are
   deleted. Judge a mob mod's spawn rates in game, not from its own defaults; a mod that
   needs bats or glow squids loses them ([mixins.md](./mixins.md#entities-and-mobs)).
10. **Tags and datapacks:** with `misc.cacheResources: true`, tags come from an on-disk
    cache between launches. If a new datapack's tags or recipes don't show, set it to
    `false` for one launch.
11. **Recipes:** the mod's own recipes aren't gregified. Swaps go through
    [gregify.py](../../tools/gregify.py) ([../updating.md](../updating.md#recipe-overrides)).

## Sources

- The notes linked from each step; `gto.py map` on the dev27 instance, 2026-11-12
