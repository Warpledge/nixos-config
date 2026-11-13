# EMI Guard

A Forge 1.20.1 client mod for GregTech Odyssey: an EMI plugin that checks what EMI
hands gtolib's recipe index at the end of its reload. When a mod breaks EMI with
`NullPointerException ... "c" is null` in `com.gtolib.ㅤࣱࣻࣾ` (the native class that
replaces EMI's `EmiRecipeIndex`), it says which recipe or category is involved, and
`emiguard-dump.txt` lets a run with the suspect mod be diffed against one without it.

## Building

```bash
python3 -I build.py <mods folder>
```

Compiles against the EMI fork jar in that folder (`emi-forge-*.jar`, Java 21 bytecode)
with JDK 21 and Gradle 8 through `nix-shell`, and copies `emiguard-<version>.jar` in.
GTO loads only the EMI plugins it lists, so add
`warpledge.emiguard.EmiGuardPlugin` under `misc.enableEmiJeiExternalPlugins` in the
instance's `config/gtocore.yaml`.

## What it does

On EMI's bake, before the index is built, it:

- drops a recipe, logging `[emiguard] dropped <id> (<class>, category <id>): <why>`,
  when its inputs, catalysts or outputs are null or hold a null, an ingredient's
  stacks are null, a stack changes after it's indexed, or it throws;
- drops recipes in a category nobody registered;
- logs recipe ids used more than once (kept);
- writes every category, workstation and recipe, sorted, to `emiguard-dump.txt` in the
  game folder (about 8 MB on dev27).

GT's machine recipes aren't in EMI's list (gtolib's index adds them itself), so its
categories show as `(no plugin recipes)` in the dump; that's normal.

## Results so far

- Quark 4.0-462 (staging, 2026-11-13): nothing dropped. The diff showed GT's 19 furnaces
  missing from `minecraft:smelting`'s workstations with Quark present
  ([candidates.md](../../0.6.0/candidates.md#integrated-mods)).
