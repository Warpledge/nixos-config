# Craft Chain overhaul follow-ups

**Goal:** the fixes and additions asked for after trying the overhaul jar (`craftchain-overhaul.jar`, Craft Chain `473ac75`) in game.

Added 2026-11-22.

**Status (2026-11-23):** the deployed jar is `e4e53a2`, the Browse tab rework
(Craftable and Short mats, one planned state per entry, hairline slots and the
bookmark chips); it follows `96fa3ba` and the three merged pull requests.

## What's already in the repo

- Craft Chain's source is `~/Projects/craftchain`; the overhaul is its commits `0d5ca51`, `9d5d222` and `473ac75`. The Craft Chain section of `personal/gaming/minecraft_servers/GTNH/2.9.0/mods.md` records the jar.
- Effects live in `ui/Fx.java` (flyers, sparks), settings in `Config.java` and `Overlay.sections()`, tabs in `ui/TabStrip.java`, the Tree tab in `DiagramView.drawDock`, the amount keys in `ChainView.drawAmountRows`.

Done in Craft Chain `3b1a8eb` (2026-11-22, built and unit-tested, not yet tried in game): effect toggles and a flyer cap, Text tabs by default, the Tree tab's amount row with Max and tool tracker, Slots names in the dock, the compact Chain view (≡ on the target card), one compact amount row with a Max count, Settings beside the dock.

## Steps left

1. Try the current jar (`e4e53a2`) in game: a fast many-stack craft (flyers stay few), the compact view on a long chain, crafting a tool from the Tree tab, Max's count, Settings beside the dock, a bookmark tab's *Set amount…* and Shift+wheel, sums in the amount field, the Tree tool display setting and the Tree tab's amount wheel.
2. Some other minor issues were seen in game with `473ac75`; ask which before closing this.
