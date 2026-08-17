# AGENTS.md

NixOS flake managing two hosts: **desktop** and **laptop**. Nixpkgs unstable,
home-manager, Niri WM, Stylix theming (Catppuccin Mocha).

## Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead.
   Validation you SHOULD run yourself before reporting done:
   `alejandra .` then `git add <new files>` then `nix flake check`.
2. **`git add` new files before `nix flake check`** — the flake ignores
   untracked files and the check fails with "file is not available".
3. **Stylix owns all theming.** Never set colors, fonts, or wallpaper in a
   module. Stylix targets already configure them; hardcoded values conflict
   with the theme or silently override it. Enable a program's theming and let
   Stylix supply the palette.
4. **Set only what was asked for.** Do not add extra options, defaults, or
   "nice to have" settings beyond the request.
5. **Surgical edits only.** Never rewrite a whole file. Never delete existing
   content, including commented-out code and disabled options.
6. **Public repo.** No passwords, API keys, tokens, or secrets.

## Looking things up

**Never write a package homepage, description, or option name from memory.**

| Need | Use |
| --- | --- |
| Package metadata | `nix eval --raw nixpkgs#<pkg>.meta.homepage` |
| nixpkgs / NixOS options | the `nixos` MCP tool |
| An app's own config syntax | `nix-shell -p <pkg> --run 'man <name>'` |
| A home-manager option | read the module in the locked HM input |

**Do not guess documentation URLs.** Fetching the web for upstream docs is a
last resort; if two fetches fail, stop and use a local source instead.

## Architecture

`hostConfig` (from `hosts/<host>/hostConfig/core.nix`) is threaded through
`specialArgs`, so every module can read it. Conditional imports in
`shared/modules/home-manager/programs/default.nix` decide what actually loads —
subdirectories under `programs/` are flat `.nix` files with **no `default.nix`
of their own**.

| Scope | Path |
| --- | --- |
| Shared user config | `shared/modules/home-manager/` |
| Shared system config | `shared/modules/nixos/` |
| Per-host toggles | `hosts/{desktop,laptop}/hostConfig/core.nix` |

**Desktop and laptop hostConfig stay symmetrical.** Every toggle you add goes
in both files with the same value unless told otherwise.

## Adding an application

1. Add the toggle to **both** host configs, in the group it belongs to
2. Create the module under `shared/modules/home-manager/programs/<group>/`
3. Add the conditional import to `programs/default.nix`:
   ```nix
   ++ lib.optionals hostConfig.media.foo [./media/foo.nix]
   ```
   The conditional belongs in `default.nix`. Do **not** wrap the module body
   in `lib.mkIf` instead.
4. `alejandra .`, `git add` the new file, `nix flake check`
5. Add it to the matching list under **Components** in `README.md`, including
   the link reference definition at the bottom of that file

## Formatting

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

Only take the arguments you use: a module that sets no packages does not need
`pkgs`.

Comments are short and explain *why*, not *what*. No session narrative, no
restating the code, no listing alternatives that were not chosen.

## Working efficiently

- **Read each file once.** Do not re-read a file unless you edited it since.
- Read only what the task needs. Two or three sibling modules are enough to
  learn a pattern.
- Batch independent shell commands into one call rather than one per step.
