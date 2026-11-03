# Mods — TerraFirmaGreg-Modern

Manually added, removed or overridden mods only. Base pack mods are not listed here.

---

## Added Mods

<!-- Template:
### Mod Name
- **Source:** Modrinth / CurseForge / GitHub
- **Version:**
- **Why:** Reason for adding
-->

### No Chat Reports (base pack override)
- **Version:** 1.20.1-v2.2.2 (downgraded from 2.2.3)
- **Why:** 2.2.3 crashed at the pause screen with `NCRCore.getProvider()` null; 2.2.2 is what the 0.12.5/0.13.7 instance ran.

### Tom's Performant Storage
- **Version:** 0.1.0+1.20.1
- **Why:** Performance-oriented storage solution

### Tom's Simple Storage Mod
- **Version:** 1.7.1
- **Why:** Simple networked storage system

### BetterBlockZ
- **Version:** 0.2.10-1.20.1-forge
- **Why:** Block improvements/additions

### Observable
- **Version:** 4.4.2
- **Why:** Performance profiling — identifies lag sources in-game

### Reconnectible Chains
- **Version:** 2.2.5
- **Why:** Allows chain blocks to connect and hang decoratively

### Zipline
- **Version:** 1.2.0
- **Why:** Traversal — ride chains/ropes as ziplines

### Distant Horizons
- **Version:** 3.3.3
- **Why:** LOD rendering for extended view distances without performance cost

### Better Climbing
- **Version:** 3
- **Why:** Improved ladder/climbing mechanics

### Shoulder Surfing Reloaded
- **Version:** 1.20.1-5.3.0
- **Why:** Improved third-person camera

### Third Person Shooting: Zero
- **Version:** 6.0.0
- **Why:** Third-person compatibility between Shoulder Surfing and TACZ

### Via Romana
- **Version:** 2.2.3+1.20.1-forge
- **Why:** Road-network fast travel; replaces Waystones

### Create: Sound of Steam
- **Version:** 0.9.1+1.20.1
- **Why:** Steam whistle instruments

### Create Railways Navigator
- **Version:** 1.20.1-beta-0.9.1-C6
- **Why:** Train scheduling and passenger information

### Dragonlib
- **Version:** 1.20.1-beta-3.0.26
- **Why:** Dependency for Create Railways Navigator; 3.0.29 stops the game loading

### Entity Texture Features
- **Version:** 7.2.6
- **Why:** Dependency for TFC Livestock Skins

### Entity Model Features
- **Version:** 3.3.12
- **Why:** Dependency for TFC Livestock Skins

### MidnightLib
- **Version:** 1.9.2
- **Why:** Dependency for Via Romana

### Data Anchor
- **Version:** 1.0.0.24
- **Why:** Dependency for Via Romana

### Yes Steve Model
- **Version:** 2.6.5-forge+mc1.20.1
- **Why:** Custom player model support
- **Note:** Needs `~/.ysm` read and mmap in the Prism AppArmor profile.

### BlueMap
- **Version:** 5.12-mc1.20-6
- **Why:** 3D web-based map renderer for the server

### Create: Extra Gauges
- **Version:** 2.0.7
- **Why:** Additional gauges and displays for Create machinery

### Chimes
- **Version:** 2.1.1
- **Why:** Ambient chime sounds

### TFC Caelum
- **Version:** 1.2
- **Why:** TFC compatibility addon for Caelum

### Caelum
- **Version:** 1.20.1-2.0.0.0
- **Why:** Sky/celestial mechanics mod

### Resourcify
- **Version:** 1.8.7
- **Why:** In-game resource pack manager

### DarkModeEverywhere
- **Version:** 1.20.1-1.2.5
- **Why:** Dark mode UI theming for menus and interfaces

---

## Removed Mods

<!-- Template:
### Mod Name
- **Why:** Reason for removal
-->

### Chunky
- **Version:** 1.3.146
- **Why:** Distant Horizons 3.3.3 crashed on world generation with `ChunkyProvider.get`; the TFG optional mods page also says DH cannot build LODs while Chunky is installed. Jar moved to `/tmp/opencode/tfg-removed/`.

### Waystones
- **Version:** 14.1.20
- **Why:** Replaced by Via Romana for fast travel. Jar moved to `/tmp/opencode/tfg-removed/`.

### Raw's Visual Keybinder
- **Version:** 1.20.1-0.1.12
- **Why:** Not reinstalled in the 0.13.17 instance.
