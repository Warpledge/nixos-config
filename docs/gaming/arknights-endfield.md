# Arknights: Endfield

Runs from Steam (app 4732690) on `dwproton-11.0-14`, as of 2026-10-15. Launch
options are in `steam-launch-parameters.md`. Before that it ran from Heroic
(Epic) on Proton-GE.

## "Unable to start ACE Setup (1-1700-2)"

The dialog reads "Unable to start ACE Setup, please check ACE directory
integrity or reinstall the game. (1-1700-2)". It means `ACE-Setup64.exe` is
missing from the game's `AntiCheatExpert/` folder.

`ACE-Base64.dll`, which `Endfield.exe` loads, builds that path relative to the
game folder and runs the setup on every launch. ACE's kernel driver can't load
under Proton, so setup never finishes and the file is needed each time; on
Windows the problem doesn't show up.

The Steam copy ships the file at
`steamapps/common/Arknights Endfiled/AntiCheatExpert/ACE-Setup64.exe` (checked
2026-10-15; `Endfiled` is Steam's spelling of the install folder). Since it's
part of Steam's depot, "Verify integrity of game files" should restore it if it
goes missing.

On the Epic copy, Epic's 1.6.0 launcher update (2026-09-14) moved the file to an
Epic-managed `games/Arknights Endfield/AntiCheatExpert/`, legendary deleted the
old path, and Heroic's repair couldn't bring it back. The fix there was copying
it into `games/EndField Game/AntiCheatExpert/` (md5
`673476ae6a94da69d28d75f2d60cb1fb`).

If ACE misbehaves after a Proton update, try `PROTON_USE_NTSYNC=0` in the launch
options first; `home/variables.nix` turns it on for every game.
