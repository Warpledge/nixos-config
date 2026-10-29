# The Side Rail

`Mod+A` shows a row of app icons down the left edge of the screen, with the last app you used open beside it. Press `Mod+A` again and both go away.

Click an icon to swap the app beside the rail. Click the one already showing to hide the rail. An app starts the first time you pick it, and a dot next to an icon means that app is running. If you switch workspace while the rail is open, the app comes with you.

## Unloading

A hidden app closes on its own after 30 minutes, so it stops using memory, and opens again the next time you pick it. The terminal, Claude Desktop and OpenCode Desktop keep running instead, since closing them ends what's running in them.

Right-click an icon to choose for that app:

- **Unload now** closes it straight away.
- **Keep running** stops it from closing on its own.
- **Unload after 5, 15 or 30 min** sets how long it can sit hidden.

Omni Settings' Side Rail page sets the same two things for each app, your own included. The right-click choice wins until you pick Reset to Default there.

An app closes the way it does when you click its ×, so it saves as it would on any quit. If it's still running in the tray a few seconds later, it's stopped. A web app comes back signed in, with Helium's cache and site data, but on its start page: a page you'd moved to inside it, or text you hadn't sent, is gone. An app that asks before closing (unsaved work) is left open for you to answer.

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

Omni Settings' Side Rail page (Niri tab) turns an app off, moves it up or down, sets how wide it opens and when it unloads, or adds your own: a web page, which opens as a Helium app window, or an app you pick from a window on screen. Like any other setting, changes wait for Apply.

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
