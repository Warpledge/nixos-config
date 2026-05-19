# hostConfig Ruleset

Patterns and workflows are in CLAUDE.md. This file has the decision tree, best practices, troubleshooting, and checklist.

## Decision Tree: Which Pattern to Use?

```
Does this need to be configurable per-host?
├─ NO → Don't use hostConfig, just put it in the module directly
└─ YES
   ├─ Is it mutually exclusive (only one choice makes sense)?
   │  └─ YES → Enum
   │         Example: windowManager, kernel
   │
   ├─ Can you have multiple items at once?
   │  └─ YES → Attribute Set
   │         Example: browsers (install Zen + Brave simultaneously)
   │
   └─ Single feature on/off?
      └─ YES → Boolean with .enable
             Example: mullvad.enable, clamav.enable
```

## Best Practices

1. **Default to current behavior** — when adding a new option, default to the state that matches the current config
2. **Use `or` for nested attrs** — `hostConfig.feature.sub or false` when accessing attrs that might not exist
3. **Group related options** — use `browsers = {...}` instead of `zenBrowser = true; braveBrowser = true`
4. **Document valid enum values** — add a comment in hostConfig listing all valid strings
5. **Verify both states** — test enabled and disabled modes
6. **Keep imports clean** — all conditionals in `default.nix`, avoid scattering `mkIf` throughout modules
7. **One option per concern** — don't create `newFeature1` and `newFeature2`; group under an attr set
8. **Sync across hosts** — add to both `hosts/desktop/hostConfig/core.nix` and `hosts/laptop/hostConfig/core.nix`

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `attribute not found` | Option missing from a host config file | Add to both `hosts/*/hostConfig/core.nix` |
| Module not loading when enabled | Wrong option name or path in conditional import | Check `default.nix` — verify `hostConfig.option` matches exactly |
| Works on desktop but not laptop | Different values per host | Check each `hosts/*/hostConfig/core.nix` |
| `nix flake check` fails | Syntax error in hostConfig file | Check for missing semicolons, unmatched braces |
| Option has no effect | Inline conditional instead of conditional import | Module loading → `lib.optionals`; config logic → `if/then/else` |
| Can't access nested attr | Accessing without checking existence | Use `hostConfig.feature.sub or default_value` |

## Validation Checklist

- [ ] Option added to **both** host `hostConfig/core.nix` files
- [ ] Conditional import placed in the relevant `default.nix`
- [ ] Option path in conditional matches definition exactly
- [ ] Tested with option enabled on at least one host
- [ ] `nix flake check` passes
- [ ] Formatted with `alejandra .`
- [ ] Enum values documented in a comment
