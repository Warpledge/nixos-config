# Omni Hand phases 3 and 4: Building extras and Guides

**Goal:** finish the Omni Hand building tools in GTNH 2.9.0: shape modifiers, more block sources and breaking in shapes (phase 3), then Guides, anchored outline shapes to build along (phase 4).

Added 2026-11-26.

## What's already in the repo

- The fork lives at `~/Projects/ezminer-balanced`, branch `balanced`, outside this repo. `docs/personal/gaming/minecraft_servers/GTNH/2.9.0/mods.md` has its build history.
- Built and tested in game: the hold-Alt menu (15-pre11), the HUD panel (15-pre12), and Building with 14 shapes, undo and Reach Upgrades (15-pre13, fork commit `420db91`).
- Installed for testing but not yet committed in the fork (2026-11-26): 15-pre14, with click-to-place input, sliders, HUD cards, bigger limits, the Pulse Wave preview, crumble and item pull.
- The Guide mode (violet) is already in the mode list, hidden until phase 4.
- Design reference: the "Omni Hand Menu Picks" artifact, https://claude.ai/artifact/5DwZPt45ZRijARcG92y4Nz. Its built-in defaults match the picks line below except the Guide outline and where guides are saved.

## warpledge's picks (2026-11-26)

```
Omni Hand menu: layout=fan, look=chip, colour=edge, hub=block, panel=left, pick=both, extras=[scroll,desc,actions,anim,dim,limits,sounds,keys] | Building: swap=split, points=both, limits=upgrades, shapes=[single,line,wall,floor,cube,dline,dwall,slope,circle,cylinder,sphere,pyramid,cone,terrain], modifiers=[mirror,array,radial], behaviour=[undo,replace,protectTE,breakShape,reach,tick,merge,backpack,ae2], feedback=[ghosts,outline,labels,needed,refused,pops,wave,undoToast,progress,rotation] | Guides: menu=actions, outline=faces, behind=xrayDim, layers=layer, placed=fade, points=empty, saved=server, colours=pick, extras=[distance,lock,anchor,counter,mismatch,hudList,buildFrom]
```

The menu and Building parts are built. Later decisions override three of those picks:

- Points are now set by clicks (pre14), not by dragging.
- Chain key + scroll was removed in pre14.
- The offhand replace filter can't be built, since 1.7.10 has no offhand.

## Phase 3 steps left

All five are built into test build 15-pre15 (2026-11-26, installed, recorded in `mods.md`), waiting for the in-game test before the fork commit. Decisions taken while building: backpacks carried and worn, then AE2 last; the preview asks the server for the reachable total; breaking skips what the tool can't harvest; the modifiers' plane and centre go through the first point or a "Set here" block; visual picks on https://claude.ai/artifact/Nj4p8Y5ivMz6my8tPeTYrG.

1. Add the Mirror, Array and Radial mirror modifiers:
   - Mirror copies the shape across X, Y or Z planes, and stairs flip.
   - Array repeats it at an offset, up to 100 times.
   - Radial mirror makes rotated copies around a point, 3 or more slices.
   - Their buttons go in the menu's action column.
2. Take blocks from backpacks in the player's inventory, and through an AE2 wireless terminal the player carries.
3. Break in shapes: left-click points break the same shape with the player's tools.
4. Merge slabs: a slab placed onto a slab makes a double slab.
5. Protect machines: never replace tile entities (GT machines, chests).

## Phase 4 steps left (Guides)

1. Add the sub-modes New, Move, Guides and Presets:
   - New: pick a shape, then set its points like a build.
   - Move: nudge, rotate or re-anchor the selected guide.
   - Guides: show, hide or select any guide in this world.
   - Presets: saved shapes you can drop anywhere.
2. Set a guide's points by right-clicking with an empty hand while Guide is the mode.
3. Save guides on the server, shared with the player's team. This needs per-world server storage and syncing to clients.
4. Draw the default look:
   - outer edges plus a faint tint on the faces
   - lines behind blocks shown dimmed
   - the layer being built bright, the others faint
   - a cell's outline gone once its block is placed
   - each guide in its own colour from a short list

   The look settings are client preferences, with these as the defaults.
5. Add the extras:
   - render distance
   - lock
   - anchor marker
   - progress counter on the HUD
   - wrong-block warning
   - nearby guides on the HUD
   - build from guide
6. Add a placement mode per guide, off by default:
   - Off: the guide is a visual guide with feedback in the world only.
   - On: right-click places blocks into the guide one at a time, and Shift+right-click with the block fills it all at once with the build animation.
