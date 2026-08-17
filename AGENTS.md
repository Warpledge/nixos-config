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

**Filter at the source — never dump a large output into the conversation.**
Man pages, store listings, and long files must be piped through `grep`/`sed`
to extract only the relevant section:

```bash
# good: a few lines
nix-shell -p zathura --run 'man zathurarc' 2>/dev/null | col -b | grep -A3 'recolor'

# bad: thousands of lines, blows the context window
nix-shell -p zathura --run 'man zathurarc'
```

Same for searching the store — target the path you want, do not list a
directory:

```bash
find /nix/store -maxdepth 4 -path '*modules/programs/zathura.nix' | head -1
```

**Cache expensive output instead of re-running it.** If you need several
different sections of the same document, dump it once and grep the file:

```bash
nix-shell -p zathura --run 'man zathurarc' 2>/dev/null | col -b > /tmp/zathurarc.txt
grep -A3 'recolor' /tmp/zathurarc.txt
grep -A3 'selection-clipboard' /tmp/zathurarc.txt
```

**Stop once you have the answer.** A package's own man page is authoritative
for its config syntax. Once you have it, do not go on to read the nixpkgs
derivation, `nix derivation` output, or the package's build inputs — those
describe how it is built, not how it is configured.

**Do check for a home-manager module** before falling back to
`home.packages`. Many programs have one, and it is the better module. One
command answers it:

```bash
find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix' | head -1
```

If that returns a path, read it and use `programs.<pkg>` instead.

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
2. Create the module under `shared/modules/home-manager/programs/<group>/`.
   Check for a home-manager module first (see above) — prefer
   `programs.<pkg>.enable` over `home.packages = [pkgs.<pkg>]`
3. Add the conditional import to `programs/default.nix`:
   ```nix
   ++ lib.optionals hostConfig.media.foo [./media/foo.nix]
   ```
   The conditional belongs in `default.nix`. Do **not** wrap the module body
   in `lib.mkIf` instead.
4. `alejandra .`, `git add` the new file, `nix flake check`
5. Add it to the matching list under **Components** in `README.md`, including
   the link reference definition at the bottom of that file

   **`README.md` is ~23 KB — never read it in full.** Locate the two regions
   you need with grep, then edit those lines directly:

   ```bash
   grep -n '^| \*\*' README.md          # the Components table rows
   grep -n '^\[.*\]: http' README.md    # the link-reference block
   ```

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
