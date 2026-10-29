# The Side Rail

`Mod+A` shows a row of app icons down the left edge of the screen, with the last app you used open beside it. Press `Mod+A` again and both go away. The apps keep running while hidden, so they come back as you left them.

Click an icon to swap the app beside the rail. Click the one already showing to hide the rail. An app starts the first time you pick it, and a dot next to an icon means that app is running but not showing. If you switch workspace while the rail is open, the app comes with you.

`Mod+C` and `Mod+X` show or hide the rail on Claude Desktop and OpenCode Desktop, the way `Mod+A` does.

The rail stays on the monitor you opened it on. Press `Mod+A` (or `Mod+C`, `Mod+X`) on another monitor to bring it and its app over.

## What's on it

Each app shows only when you have it turned on:

| App | What it is |
| --- | --- |
| Terminal | A kitty window in the config folder (`/etc/nixos-config`), for Claude Code, opencode or anything else |
| Ask Brave | Brave Search's AI answers, as a Helium app window |
| Claude Desktop | The Claude desktop app |
| OpenCode Desktop | OpenCode's desktop app |
| llama-swap | llama-swap's page for your local models |
| Open WebUI | Chat with your local models in the browser |

Omni Settings' Side Rail page (Niri tab) turns an app off, moves it up or down, sets how wide it opens, or adds your own: a web page, which opens as a Helium app window, or an app you pick from a window on screen. Like any other setting, changes wait for Apply.

## Width

Each app remembers its own width. Hold `Mod` and drag with the right mouse button to make it wider or narrower. Right-click its icon on the rail for Narrow and Wide, or Reset to Default to go back to the width set in Omni Settings.

## Terminal tabs

The terminal is a normal kitty window, so each tab is its own shell.

| Keys | What it does |
| --- | --- |
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+Q` | Close the tab |
| `Ctrl+Shift+Right` / `Left` | Next / previous tab |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab |
| `Ctrl+Shift+Alt+1` to `9` | Go to that tab |
| `Ctrl+Shift+.` / `,` | Move the tab right / left |
| `Ctrl+Shift+Alt+T` | Rename the tab |

Typing `exit` closes a tab too. Closing the last one closes the terminal, and picking it on the rail starts a new one.
