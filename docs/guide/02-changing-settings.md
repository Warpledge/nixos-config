# Changing Settings

`Mod+S` opens Omni Settings as a panel on the right of the screen, and so does pushing the mouse into the top-right corner. It closes when the mouse leaves it, or when you press `Mod+S` or `Esc` again, but stays open while you're typing or a question is up. The app launcher (`Mod+Space`) opens it as a window instead. Both show the same thing, and a rebuild keeps going if you close either. Drag the panel's left edge to make it wider or narrower; it keeps that width until you change it, and double-clicking the edge puts it back.

## Finding Your Way Around

The icons across the top are tabs. Each tab is one long page you scroll through, with a divider naming each of its pages; the icons down the right edge jump to them:

- **Maintenance**: updates, pinned versions, freeing space and versions, then Git, Flatpaks and Backups
- **System**: Users, and the computer and personal setting pages
- **Packages**: searching for software, the app switches (Default Packages) and what you've installed yourself (User Packages)
- **Niri**: the desktop's shell settings and window rules
- **Hardware**: firmware updates, and the battery and dGPU pages on a laptop
- **Gaming**: launch options, Proton versions, and the game launchers and tools to install
- **AI**: Claude and the local AI models
- **Docs**: these guides and the game notes

Start typing anywhere outside a text field to search every page and setting, including the shell's own settings.

## Making a Change

1. Change a switch, dropdown or text field. Nothing happens to the system yet: the row is marked as changed, and the Apply button lights up.
2. Make as many changes as you like across any pages.
3. **Review** shows every pending change and the lines it will change in each file.
4. **Discard** throws them all away.
5. **Apply** asks how to use them:
   - **Apply Now** saves, rebuilds and switches. Most changes work straight away.
   - **At Next Restart** saves and rebuilds, and the new version starts when you restart. Apply suggests this for kernel and window manager changes.
   - **Preview** builds and shows what would change, then puts everything back. Your pending changes stay, and the run page offers Apply Now.

Your password is asked once per run, in the shell's full-screen prompt.

## While It Runs

The run page shows each step, what it's building, and at the end what changed (packages added, removed or updated, and services restarted). **Stop** cancels the build and nothing is switched. If the run fails, **Undo My Changes** puts your files back; see [When Things Go Wrong](08-when-things-go-wrong.md).

Closing Omni Settings doesn't stop a run. Open it again to see where it's got to; when a run finishes with Omni Settings closed, you get a notification.

## Going Back to the Default

A setting that differs from the default has a reset button beside it. Zed, Dux Files and FreeTube get one on their app switch too: it puts back every setting the config declares for that app and keeps the old file as `.old`.

## Change For

If you're listed on more than one computer, app pages start with **Change For**:

- **This computer** (the default) changes the setting here only.
- **Another computer** saves it for that one, without a rebuild here. It applies the next time that computer rebuilds.
- **All of them** saves it to your own settings file, for every computer.

## What's New

When the config gains a setting your file doesn't have yet, a **What's New** page appears. **Add Them With Their Defaults** stages them like any other change, and **Dismiss** hides the page until something newer arrives.

## The Settings Pages

- **System**: the computer's name, desktop and kernel
- **Boot**: how long the boot menu waits and how many generations it keeps
- **Language & Input**: time zone, language and keyboard layout
- **Devices**: Bluetooth, printing and the mouse pointer
- **Services**: background services, and under **Running Now** each one's state, last log lines and a restart button
- **Default Apps**: which app opens links, text files, terminal programs and folders. Change these here: picking a default in the shell's settings doesn't survive a rebuild. The choices are listed in [`lib/default-apps.nix`](../../lib/default-apps.nix).
- **Startup**: variables every program you start sees, and programs started with the desktop
- **File Types**: which app opens one file type, in front of the Default Apps choices

The **Network** tab holds **Tools** (a connection check, a speed test and how DNS is resolved), **Connections** (Wi-Fi, wired and VPN connections, and finding file shares), **Firewall** (what other devices can reach here), **Blocking** (ad and tracker lists, domains to let through, and a lookup for whether a site is blocked) and **VPN** (Mullvad and the relay in use). The **Security** tab holds **AppArmor** (each app profile, what it would have blocked, and switching one to enforce), **SSH** (the SSH server, the keys that may log in as you, and your own keys, which it can copy, add to GitHub or make), **Antivirus** and the security apps.

Monitors, sound, Wi-Fi, keyboard shortcuts, the bar, wallpaper and lock screen are the shell's own settings. Their pages (on the Niri tab, and Wi-Fi under Network → Connections) open the matching tab of the shell's settings window, and those changes save straight away with no rebuild.

## Users

Users lists who can log in, and holds your name and email for git commits. An admin can add someone: a login name, a password, and whether they're an admin. **Add and Rebuild** creates their settings and rebuilds. Each person changes their own apps by logging in as themselves.
