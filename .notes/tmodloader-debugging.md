# tModLoader - File Paths & Log Locations

**Quick reference for finding tModLoader data, logs, and configuration files.**

## Installation & Main Directory

```
~/.local/share/Steam/steamapps/common/tModLoader/
```

## User Data & World Files

```
~/.local/share/Terraria/tModLoader/
```

### Important Subdirectories
- **Mods/** - Installed .tmod files and mod data
- **Worlds/** - World save files
- **Players/** - Character saves
- **ModConfigs/** - Individual mod configuration JSON files

## Log Files

**Client Logs Location:**
```
~/.local/share/Steam/steamapps/common/tModLoader/tModLoader-Logs/
```

### Key Log Files
| File | Purpose |
|------|---------|
| `client.log` | Main game log (largest, contains errors/warnings) |
| `server.log` | Multiplayer server log |
| `Launch.log` | Game startup diagnostics |
| `environment-client.log` | Environment/system info at launch |
| `terrariasteamclient.log` | Steam integration logs |
| `Natives.log` | Native library load information |

## Configuration Files

**Mod List:**
```
~/.local/share/Terraria/tModLoader/Mods/enabled.json
~/.local/share/Terraria/tModLoader/Mods/LastLaunchedMods.txt
```

**Game Config:**
```
~/.local/share/Terraria/tModLoader/config.json
~/.local/share/Terraria/tModLoader/input profiles.json
```

**Mod-Specific Config:**
```
~/.local/share/Terraria/tModLoader/ModConfigs/
```

## Common Log Queries

**Extract errors/warnings from client log:**
```bash
grep -E "error|Error|ERROR|failed|Failed|FAILED|exception|Exception|warning|Warning|WARNING" \
  ~/.local/share/Steam/steamapps/common/tModLoader/tModLoader-Logs/client.log
```

**Check RAM usage during last session:**
```bash
grep -i "RAM\|memory\|Mods using the most RAM" \
  ~/.local/share/Steam/steamapps/common/tModLoader/tModLoader-Logs/client.log
```

**View last entries of client log (gameplay session):**
```bash
tail -200 ~/.local/share/Steam/steamapps/common/tModLoader/tModLoader-Logs/client.log
```

## World Information

- **World saves:** `~/.local/share/Terraria/tModLoader/Worlds/`
- **Player data:** `~/.local/share/Terraria/tModLoader/Players/`
- **World stats:** Stored in .wld files (binary format)

## Temporary/Debug Files

- **IL Dumps:** `~/.local/share/Steam/steamapps/common/tModLoader/tModLoader-Logs/ILDumps/`
- **Old logs:** `~/.local/share/Steam/steamapps/common/tModLoader/tModLoader-Logs/Old/`
- **Crash logs:** `~/.local/share/Steam/steamapps/common/tModLoader/client-crashlog.txt`

## Notes

- **Log files are active during gameplay** - Client.log gets appended as the game runs
- **Mod data persists** - Even if a mod is disabled, its config remains in ModConfigs/
- **Save files are large** - Full world + player data can be several GB with many mods
- **Magic Storage items count** - Each item instance in storage adds to RAM usage (1400+ items = notable overhead)
