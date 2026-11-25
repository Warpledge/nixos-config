# Port Craft Chain to 1.20.1 with EMI for GregTech Odyssey

**Goal:** bring Craft Chain, the GTNH crafting overlay, to Minecraft 1.20.1 with EMI so it works in the GregTech Odyssey (GTO) modpack: plan a crafting chain from what you have, then craft the whole chain.

Added 2026-11-21.

## What's already in the repo

- Nothing in this repo yet. The mod's source is `~/Projects/craftchain` (its own git repo), built for GTNH 2.9 (1.7.10) against GTNH's NotEnoughItems 2.8.171-GTNH. The Craft Chain section of `personal/gaming/minecraft_servers/GTNH/2.9.0/mods.md` records each version.
- These parts of the mod don't depend on Minecraft or NEI, so they port as they are: the code in its `chain/` package (the planner, the "can make" search, tool handling, leftovers, saved picks). Its tests use plain strings for items.
- The UI ideas carry over (docked panel, Craftable and Chain tabs, recipe pop-out, quick-craft sub-chains), but the drawing code needs rewriting for modern Minecraft.

## Only in GTNH's NEI, so needs replacing

These are additions in GTNH's NEI fork, not in NEI itself (NotEnoughItems source, tag 2.8.171-GTNH):

- `AutoCraftingManager`: crafts the whole chain, filling the grid step after step.
- `RecipeChainMath`: works out the totals each step is crafted for.
- `BookmarkPanel.pullBookmarkItems`: pulls ingredients out of storage (AE2, Simple Storage) through NEI's storage handlers.
- NEI's crafting recipe handlers, which the recipe index reads.

## What EMI on 1.20.1 offers

From the DeepWiki summary of `emilyploszaj/emi`, looked up 2026-11-21:

- Every recipe through `EmiRecipe`, enough to build the recipe index.
- A recipe tree that plans a chain and shows its costs. As far as found, it doesn't craft the chain.
- Grid filling for one recipe at a time through `StandardRecipeHandler` and `EmiRecipeFiller`. When you're the host it moves items with slot clicks; on a server it sends a fill request.
- No general way to take items from storage. Each mod handles its own; AE2's EMI support covers its crafting terminal.

## Steps left

1. Set up a 1.20.1 project for the modpack's loader and EMI version (check what GTO ships), and copy `chain/` over with its tests.
2. Build the recipe index from EMI's recipes, keeping the shaped-slot positions and tool detection (GTCEu tools on 1.20.1 differ from GT5's).
3. Write a chain runner: fill the grid for one step, take the output, go to the next. This replaces `AutoCraftingManager`.
4. Storage: support the AE2 crafting terminal through its EMI support first, then other storage mods one at a time, or start with inventory-only crafting.
5. Decide whether to add a small server-side part. Modern Minecraft is stricter about clients moving items, so one would make chain crafting more reliable, but then the server needs the jar too.
6. Rebuild the UI on 1.20.1's screen and rendering code.

Rough size, estimated 2026-11-21: a bit more work than the original GTNH version, mostly the chain runner and storage support.

## Sources

- EMI's recipe handlers, `StandardRecipeHandler`, `EmiRecipeFiller` and recipe tree: DeepWiki summary of `emilyploszaj/emi`, https://deepwiki.com/search/843b7f3e-4f57-4440-925f-2083c64fa1cb
- GTNH NEI's chain and auto-craft classes: https://github.com/GTNewHorizons/NotEnoughItems/tree/2.8.171-GTNH
