# AGENTS.md

NixOS flake managing two hosts: **desktop** and **laptop**. Nixpkgs unstable,
home-manager, Niri WM, Stylix theming.

## Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead.
   Validation commands you SHOULD run yourself before reporting done:
   `alejandra .` and `nix flake check`.
2. **`git add` new files before `nix flake check`** — the flake ignores
   untracked files and the check will fail with "file is not available".
3. **Surgical edits only.** Never rewrite a whole file. Never delete existing
   content, including commented-out code and disabled options.
4. **Public repo.** No passwords, API keys, tokens, or secrets.
5. **Never write a package homepage or description from memory.** Get it from
   the `nixos` MCP tool, or `nix eval --raw nixpkgs#<pkg>.meta.homepage`.

## Architecture

`hostConfig` (from `hosts/<host>/hostConfig/core.nix`) is threaded through
`specialArgs`, so every module can read it. Conditional imports in each
directory's `default.nix` decide what actually loads.

| Scope | Path |
| --- | --- |
| Shared user config | `shared/modules/home-manager/` |
| Shared system config | `shared/modules/nixos/` |
| Per-host toggles | `hosts/{desktop,laptop}/hostConfig/core.nix` |

**Desktop and laptop hostConfig stay symmetrical.** Every toggle you add goes
in both files, with the same value unless told otherwise.

## Adding an application

1. Add the toggle to **both** host configs, in the group it belongs to
2. Create the module in the right subdirectory under
   `shared/modules/home-manager/programs/`
3. Add the conditional import to that subdirectory's `default.nix`:
   ```nix
   ++ lib.optionals hostConfig.media.foo [./media/foo.nix]
   ```
   The conditional belongs in `default.nix`. Do **not** wrap the module body
   in `lib.mkIf` instead.
4. `git add` the new file, then run `nix flake check`
5. Add it to the matching list under **Components** in `README.md`, including
   the link reference definition at the bottom of that file

## Formatting

Run `alejandra .` before reporting done.

Every module opens with a banner. **Copy it byte-for-byte from a neighbouring
module in the same directory** — note the trailing `#` closing both rule lines:

```nix
#=====================================================================#
# GRAYJAY
#=====================================================================#
{pkgs, ...}: {
  home.packages = [pkgs.grayjay];
}
```

Comments are short and explain *why*, not *what*. No session narrative, no
restating the code, no listing alternatives that were not chosen.
