# COSMIC and cosmic-manager

**cosmic-manager** (COSMIC): nixpkgs ships no home-manager options for COSMIC, so the `wayland.desktopManager.cosmic.*` surface comes from the `cosmic-manager` flake input, imported in `cosmic-home/default.nix`. Two things make it behave unlike the rest of the repo:

- **It does not symlink.** It renders the options to a JSON manifest and runs `cosmic-ctl apply` from a HM activation script, so `~/.config/cosmic/<component>/v1/<key>` stays a real writable file and COSMIC Settings keeps working. Declared keys are rewritten each activation; undeclared keys are never touched. Do **not** go back to `xdg.configFile` + `force = true` for COSMIC: that is what made the Settings GUI read-only before.
- **Never put `$` in a COSMIC `Spawn` string.** cosmic-manager serializes RON with `lib.strings.escapeNixString`, which emits `\$`. RON only accepts `\' \" \\ \n \r \t \0 \x \u`, so the `ron` parser rejects the whole file and **every** custom shortcut silently dies. Put command substitutions in a `writeShellScriptBin` and spawn that instead; `core/binds.nix` does this for the screen-recorder binds. Re-test if the input is ever bumped.

`panels` is authoritative over `com.system76.CosmicPanel/v1/entries`: a panel omitted from the list is deleted. Only `Panel` is declared, so COSMIC's default Dock is removed, which mirrors the DMS bar, which runs with `showDock = false`. `name` and `margin` are the only non-nullable panel options, so a placeholder panel still needs both.

**Third-party applets** (minimon, privacy indicator, caffeine) have no typed cosmic-manager module: they are plain cosmic-config components reachable through the generic `wayland.desktopManager.cosmic.configFile."<app-id>"` escape hatch. A Rust struct deriving `CosmicConfigEntry` writes **one file per field**, and a struct marked `#[serde(default)]` accepts a **partial** value. Three traps, all hit in practice:

- **The component ID can depend on where the applet is hosted.** minimon in the panel reads `io.github.cosmic_utils.minimon-applet-panel`; the un-suffixed `io.github.cosmic_utils.minimon-applet` is the dock/standalone instance. Declaring the wrong one writes a config dir nothing reads and fails silently. Always check `ls -d ~/.config/cosmic/*<applet>*` before declaring.
- **Partial structs reset what they omit.** Fine for a struct you fully own, destructive for one tuned in a GUI: minimon persists ~3.7 KB per sensor including all colour fields. To capture GUI-tuned state, commit the RON and feed it back with `{__type = "raw"; value = builtins.readFile ./file.ron;}` rather than transcribing fields.
- **Hardware-keyed maps never port.** minimon's `gpus` is keyed per GPU, so it cannot be shared between desktop and laptop.

When a schema is undocumented, tune it once in the GUI and run `cosmic-ctl backup <out.json>` to dump the exact RON rather than guessing.

The COSMIC panel is a deliberate port of the DMS "Main Bar" in `niri-home/shell/dms/settings.json` (`barConfigs[0]`): widget order, anchor, opacity and output all trace back to it, and `shell/panel.nix` annotates each applet with the DMS widget it stands in for. **Rearranging either bar means updating the other.** Verify an applet ID before adding it: `ls $(nix build --no-link --print-out-paths nixpkgs#cosmic-applets)/share/applications`.
