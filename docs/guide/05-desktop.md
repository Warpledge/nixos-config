# Using the Desktop

The desktop is two parts: **niri**, which places windows, and **DankMaterialShell** (DMS), the bar, launcher, notifications, lock screen and settings window on top of it.

`Mod` is the Super (Windows) key. `Mod+/` shows every shortcut on screen.

## How Windows Are Laid Out

Niri doesn't shrink windows to fit. Each new window opens as a column to the right, and the row of columns scrolls sideways past the screen's edges. Move between them with `Mod+Left`/`Mod+Right`, or `Mod` with the scroll wheel. `Mod+Tab` zooms out to show everything.

Workspaces stack vertically, one row of columns each. `Mod+1` to `Mod+9` jump to one, and `Mod+Up`/`Mod+Down` move between them. Each monitor has its own.

## Shortcuts

| Keys | What it does |
| --- | --- |
| `Mod+Space` | App launcher |
| `Mod+Return` / `Mod+T` | Terminal |
| `Mod+B` / `Mod+E` | Browser / files |
| `Mod+S` | Omni Settings |
| `Mod+Comma` | Shell settings |
| `Mod+Q` | Close the window |
| `Mod+F` / `Mod+Shift+F` | Maximize / fullscreen |
| `` Mod+` `` | Float or tile the window |
| `Mod+G` | Cycle the column's width |
| `Mod+Alt+1` / `2` / `3` | Column width 1/3, 1/2, 2/3 |
| `Mod+Shift+Left` / `Right` | Move the column |
| `Mod+Shift+1` to `9` | Send the window to a workspace |
| `Mod+BracketLeft` / `Right` | Stack the window into the next column, or out of it |
| `Mod+Backslash` | Tabbed column on or off |
| `Mod+Alt+Left` / `Right` | Focus the next monitor (add `Shift` to move the window) |
| `Mod+V` | Clipboard history |
| `Mod+N` | Notepad |
| `Mod+P` | Task manager |
| `Ctrl+Alt+Delete` | Resources, the system monitor |
| `Mod+L` / `Mod+K` | Lock screen / power menu |
| `Print` | Screenshot a region (`Mod+Print` a window, `Mod+Shift+Print` the monitor) |
| `Mod+End` | Start or stop a screen recording |
| `Mod+W` | Wallpapers |
| `Mod+R` | Restart the shell, if the bar or a panel misbehaves |
| `Mod+Escape` | Take shortcuts back from an app (games and remote desktops can hold them) |

Add your own shortcuts in the shell settings (Keyboard Shortcuts); yours win over the config's. The config's are in [`binds.nix`](../../modules/wm/niri/home/core/binds.nix), and the shell's (launcher, screenshots, lock and so on) in [`dms/default.nix`](../../modules/wm/niri/home/dms/default.nix).

## Look and Colours

Pick a wallpaper with `Mod+W` and a colour theme in the shell settings (`Mod+Comma` → Theme & Colors). The theme recolours the shell and most apps: terminals, GTK and Qt apps, Zed, Discord and others. GTK 4 apps pick up a new theme when they next start. Fonts, icons and the mouse pointer come from the config ([`modules/theme/`](../../modules/theme/)).

`Mod+Y` cycles blur presets, and `Mod+Shift+T` or `Mod+Shift+Y` turns a window's see-through effect off and on.

## Window Rules

Niri → **Window Rules** decides how particular apps open: floating, on a given workspace or monitor, a set size, and so on. **Pick a Window** fills in a rule from a window you click. Admins can add, edit and remove rules; they apply after a rebuild. The rules are kept in [`window-rules.json`](../../modules/wm/niri/home/core/window-rules.json), and this computer's monitor layout in [`niri.nix`](../../machines/{machine}/wm/niri.nix).
