# GTO 0.6.0 Internals

What GregTech Odyssey itself adds and patches, so a mod can be judged against it before
it goes into staging. Everything here was read from 0.6.0-dev27 (`gtocore` 26.11.1,
jars dated 2026-11-03) on 2026-11-12. A new dev build can change any of it, so rerun
`gto.py map` after an update and check the counts below still hold.

## Sub-Notes

- [new-mod-checklist.md](./new-mod-checklist.md): the steps for checking a candidate
  mod, and the gotchas already found
- [jars-and-forks.md](./jars-and-forks.md): GTO's own jars, the sealed code, and the
  six mods it ships as forks
- [mixins.md](./mixins.md): what GTO's 405 mixins patch, grouped by target mod, with
  the hot spots for add-ons
- [rules.md](./rules.md): all 102 world rules with their preset values
- [content.md](./content.md): GTO's dimensions, worldgen, loot and tags, and where its
  machines, materials and recipes come from

## Regenerating

```bash
python3 -I ../../tools/gto.py map GregTech.Odyssey-0.6.0-dev27 > map.txt
```

`map` lists every GTO jar and fork (mod IDs, dependencies, ModLauncher services,
access transformers, sealed method bodies, jar-in-jar), then GTO's mixins by target mod
and class, then every class GTO patches that another installed mod also patches.
Mixins marked `[Overwrite]`, `[Redirect]` or `[ModifyConstant]` replace code outright;
two mods doing that to the same method don't combine. `--summary` gives the counts only.

`map --mod <jar>` checks a candidate instead: mod ID clashes, dependencies the pack
lacks, dependencies on a GTO fork, and each of its mixins whose target GTO owns, forks
or patches. The targets are read from each mixin class's `@Mixin` annotation, so a mixin
a config plugin switches off at runtime still shows.

## Reading GTO's code

- `com.gtocore` is public: [GregTech-Odyssey/GTOCore-Main][core], branch `0.6.0`. Its
  `docs/` has `forked-dependencies.md`, `emi-integration.md`, `world-rules.md` and
  `gtolib.md` (all Chinese).
- `com.gtolib` is a private submodule. Its mixin package stays readable in the jar, so
  `nix run nixpkgs#cfr -- <class files> --outputdir <dir>` shows each injection point;
  the logic behind it is ProGuard-renamed (`ㅤ...` names) and mostly sealed (see
  [jars-and-forks.md](./jars-and-forks.md#sealed-code)).
- GTO's config is `config/gtocore.yaml` (comments in Chinese and English), separate
  from the world rules in `config/gtocore-rules.txt`.

## Sources

- The dev27 instance's `mods/` jars, read with `gto.py map` and CFR 0.152
- [GTOCore-Main `0.6.0`][core] `docs/` and `src/main/java/com/gtocore/`, read
  2026-11-12

[core]: https://github.com/GregTech-Odyssey/GTOCore-Main/tree/0.6.0
