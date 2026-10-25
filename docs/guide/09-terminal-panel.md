# The Terminal Panel

`Mod+A` opens a terminal that slides in from the left edge of the screen, in the config folder (`/etc/nixos-config`). It's there for Claude Code and opencode, but it opens on a plain shell, so you start whichever you want. The shortcut only exists when kitty and at least one of Claude Code or opencode are switched on (Omni Settings' AI tab → Cloud AI).

## Showing and Hiding It

Press `Mod+A` to show the panel and press it again to hide it. Hiding it doesn't close anything: whatever runs in its tabs keeps going and is still there next time. The panel takes the keyboard when it opens or when you click into it.

## Starting an Agent

Type `claude` for Claude Code or `opencode` for opencode. Either works on the folder you're in, which starts as the config; `cd` somewhere else first to work on another project.

Quit the agent (`/exit` in both) and you're back at the shell.

## Tabs

Each tab is its own shell, so you can run Claude Code in one and opencode in another, or several sessions on different folders.

| Keys | What it does |
| --- | --- |
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+Q` | Close the tab |
| `Ctrl+Shift+Right` / `Left` | Next / previous tab |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab |
| `Ctrl+Shift+Alt+1` to `9` | Go to that tab |
| `Ctrl+Shift+.` / `,` | Move the tab right / left |
| `Ctrl+Shift+Alt+T` | Rename the tab |

Typing `exit` closes a tab too. Closing the last one quits the panel, and the next `Mod+A` starts a new one.

These are kitty's own shortcuts, the same as in the normal terminal window (`Mod+Return`). Kitty's settings are in [`kitty.nix`](../../modules/home/programs/terminals/kitty.nix) and the panel's in [`ai-panel.nix`](../../modules/home/programs/ai/ai-panel.nix). Change `Mod+A` itself on Omni Settings' Keybinds page (Niri tab).
