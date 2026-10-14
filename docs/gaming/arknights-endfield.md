# Arknights: Endfield

Runs from Heroic (Epic) on Proton-GE.

## "Unable to start ACE Setup (1-1700-2)"

The dialog reads "Unable to start ACE Setup, please check ACE directory
integrity or reinstall the game. (1-1700-2)". It means `ACE-Setup64.exe` is
missing from `<install>/games/EndField Game/AntiCheatExpert/`.

`ACE-Base64.dll`, which `Endfield.exe` loads, builds that path relative to the
game folder and runs the setup on every launch. ACE's kernel driver can't load
under Proton, so setup never finishes and the file is needed each time; on
Windows the problem doesn't show up.

Epic's 1.6.0 launcher update (2026-09-14) moved the file to an Epic-managed
`games/Arknights Endfield/AntiCheatExpert/`, and legendary deletes any path the
new manifest drops. Heroic's verify or repair won't bring it back, since the
manifest no longer puts it in the game folder. Expect it to go missing again
after updates.

Copy it back (verified 2026-09-18):

```bash
cp "<install>/games/Arknights Endfield/AntiCheatExpert/ACE-Setup64.exe" \
   "<install>/games/EndField Game/AntiCheatExpert/"
```

Both copies are byte-identical (md5 `673476ae6a94da69d28d75f2d60cb1fb`).

The game's Heroic config also sets `PROTON_USE_NTSYNC=1`. If ACE misbehaves
after a Proton update, clear that first.
