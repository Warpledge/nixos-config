# GTO's Jars and Forks

From `gto.py map` on 0.6.0-dev27, 2026-11-12.

## GTO's own jars

| Jar | Mod IDs | What it is |
| --- | --- | --- |
| `gtocore-forge-1.20.1-26.11.1.jar` | `gtocore`, `gtolib` | The pack's core: 405 mixins (312 common, 93 client), 83 access transformer lines, 1140 sealed method bodies, commons-math3 as jar-in-jar |
| `gto-seal-runtime-1.0.jar` | none | A ModLauncher `ITransformationService` with native loaders for Linux, Windows and macOS; runs the sealed bodies |
| `gtoutils-forge-1.20.1-26.10.3.jar` | `gtoutils` | 5 mixins; required by gtocore, Botania and Ars Nouveau |
| `gtorenders-forge-1.20.1-26.10.4.jar` | `gtorenders` | 1 client mixin; required by gtocore, Botania and Ars Nouveau |
| `datasynclib-forge-1.20.1-26.11.2.jar` | `datasynclib` | Field sync and NBT persistence framework by nutant233; required by gtocore, Botania and Ars Nouveau |

gtocore requires `gtceu` 26.10.70+, `ae2` 15.2610.29+, `ars_nouveau` 4.12.12+,
`botania` 457.2610.9+, `ad_astra`, `datasynclib`, `gtoutils` and `gtorenders`;
`deeperdarker` is optional. Removing any required one stops the game at the mod
loading screen, and removing a mod GTO only mixes into crashes at mixin apply unless
the mixin's config plugin skips it (see [mixins.md](./mixins.md#config-plugins)).

### Sealed code

gtocore's manifest marks the jar `GTO-Seal: 1` and `GTO-Core-Obfuscated: 1`. gtolib
classes are ProGuard-renamed with a dictionary of `U+3164` plus combining marks, shuffled
every build, so names differ between dev builds. 1140 method bodies sit encrypted in
`native0/native/**.prod.bin` and are run by `gto-seal-runtime`'s native library. Only
`com.gtolib.mixin.**`, the capability and machine-feature interfaces, and classes marked
`@KeepName` keep their names (GTOCore-Main `docs/gtolib.md`).

A crash inside sealed code shows mangled frames; GTO's devs map them back with a private
mapping file. Report those upstream with the full log rather than trying to read them.

## Forks

GTO builds six mods from its own forks (GTOCore-Main `docs/forked-dependencies.md`).
Each keeps the upstream mod ID, so a mod that depends on it loads, but its API is GTO's
version.

| Mod | Jar in dev27 | Fork | Ties to GTO |
| --- | --- | --- | --- |
| GregTech Modern | `gtceu-1.20.1-forge-1.20.1-26.11.08.jar` | [GregTech-Modern][gtm] | 54 own mixins; requires `ae2`, `ldlib`, `configuration` |
| Applied Energistics 2 | `appliedenergistics2-forge-1.20.1-15.2611.1.jar` | [Applied-Energistics-2-gto][ae2] | Requires EMI (the fork) and GuideME; holds AE2's EMI module |
| ExtendedAE (`expatternprovider`) | `extendedae-forge-1.20.1-1.26.1008.jar` | [ExtendedAE][eae] | Built against the AE2 and EMI forks |
| EMI | `emi-forge-1.20.1-1.1.1034.jar` | [EMI-gto][emi] | Bundles EMI Trades (`emitrades`); never install upstream EMI or EMI Trades beside it |
| Botania | `Botania-forge-1.20.1-457.2611.1.jar` | [Botania-gto][bot] | Requires `datasynclib`, `gtoutils`, `gtorenders` |
| Ars Nouveau | `ars_nouveau-1.20.1-forge-1.20.1-4.12.24.jar` | [Ars-Nouveau-gto][ars] | Requires `datasynclib`, `gtoutils`, `gtorenders`; bundles MixinExtras 0.2.0-beta.8 |

Version numbers are date-based (`26.11.08`, `15.2611.1`), so an add-on's
`versionRange` against the upstream numbering (`[1.6,)`, `[15.0,)`) passes even when
the add-on was built for an API the fork changed. Botania and Ars Nouveau can't be
swapped for upstream jars: they require GTO's libraries.

### EMI-gto

Based on upstream EMI `1.1.24+1.20.1` (commit `23d251e`), keeping Forge mappings and
general fixes; the Crazerium branch's planner, favourite groups, recipe sharing and
batch crafting were removed. When AE2 is present, EMI's item and fluid keys are AE2's
`AEItemKey`/`AEFluidKey`, compared by reference. A plugin that builds its own
`EmiStack` comparisons on NBT goes through deprecated paths (`COMPARE_NBT`,
`Comparison.compareNbt()`), kept for binary compatibility only. The old
`dev.emi.emi.platform.EmiClient` class is kept for Sophisticated Core.
(GTOCore-Main `docs/emi-integration.md`.)

GTO also decides which EMI and JEI plugins load at all; see
[mixins.md](./mixins.md#emi-and-jei).

## Sources

- `gto.py map` output and each jar's `META-INF/mods.toml` and `MANIFEST.MF`
- GTOCore-Main `0.6.0` `docs/forked-dependencies.md`, `docs/emi-integration.md`,
  `docs/gtolib.md`, read 2026-11-12

[gtm]: https://github.com/GregTech-Odyssey/GregTech-Modern
[ae2]: https://github.com/GregTech-Odyssey/Applied-Energistics-2-gto
[eae]: https://github.com/GregTech-Odyssey/ExtendedAE
[emi]: https://github.com/GregTech-Odyssey/EMI-gto
[bot]: https://github.com/GregTech-Odyssey/Botania-gto
[ars]: https://github.com/GregTech-Odyssey/Ars-Nouveau-gto
