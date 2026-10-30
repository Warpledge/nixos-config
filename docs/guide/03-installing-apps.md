# Installing Apps

There are three ways to get software, and they suit different apps.

## Default Packages: Apps the Config Sets Up

Packages → **Default Packages** has a page per kind of app (Browsers, Media, Office…), and the Gaming tab's **Apps** page holds the game launchers and tools. Each switch installs an app *and* sets it up: its settings, theme, file types, and sometimes a service or a security profile. Use these whenever the app you want has a switch.

Turn a switch on or off, then Apply. The button beside a switch opens the file that sets the app up, if you're curious how. Which switch loads which file is in [`modules/home/programs/default.nix`](../../modules/home/programs/default.nix).

## Search: Any Package from nixpkgs

The search box at the top of the Packages tab looks through nixpkgs, the main package collection (well over 100,000 packages). The list is downloaded the first time and refreshed once a week. Open a result to see its homepage, licence and what command it runs.

**Install** asks for a category (Media, Tools, or one you type), then stages it like any other change. Apply to install it. These packages come as they are: no extra setup, just the program.

**User Packages** lists what you've installed this way, by category. Each one has **Move** (another category) and **Uninstall**; a pending removal has **Undo** until you Apply. They're saved as `userPackages` in [your settings file](../../users/{user}/settings.nix), and [`user-packages.nix`](../../modules/home/programs/user-packages.nix) installs them.

## Flatpaks: Apps Outside nixpkgs

Some apps only ship as a Flatpak. Maintenance → **Flatpaks** needs Flatpak turned on for the computer (an admin's switch, which loads [`flatpak.nix`](../../modules/nixos/services/runtimes/flatpak.nix)). The page then:

- checks for updates and updates everything
- removes runtimes nothing uses any more, and repairs the installation
- lists each installed app with a switch, which uninstalls or reinstalls it straight away (no rebuild)
- opens Flatseal, which shows and changes what each Flatpak may reach

Install new Flatpaks from Flathub with `flatpak install flathub <app id>` in a terminal. Prefer Default Packages or Search when the app is there: Flatpaks update on their own schedule and can't be pinned to a version.

## Trying an App Without Installing It

In a terminal, `run <package>` downloads a package and starts it once, without installing anything:

```
run cowsay hello
```

It's gone from your apps afterwards (garbage collection deletes the download later). If you like it, install it with Search.

## Which App Opens What

System → **Default Apps** picks your browser, text editor, terminal and file manager. These decide what opens links and files, and what `Mod+B`, `Mod+E`, `Mod+Return` and `Mod+Z` start. A pick whose app is switched off falls back to the first one you have of that kind.
