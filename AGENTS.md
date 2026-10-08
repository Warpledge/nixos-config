# AGENTS.md

NixOS flake managing two hosts: **desktop** and **laptop**. Nixpkgs unstable,
home-manager, Niri WM, Stylix theming (Catppuccin Mocha).

## Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead.
   Validation you SHOULD run yourself before reporting done:
   `alejandra .` then `git add <new files>` then `nix flake check`.
   Commit only when asked (see rule 7); pushing and history rewrites stay
   with the user.
2. **`git add` new files before `nix flake check`** — the flake ignores
   untracked files and the check fails with "file is not available".
3. **Stylix owns all theming.** Never set colors, fonts, or wallpaper in a
   module. Stylix targets already configure them; hardcoded values conflict
   with the theme or silently override it. Enable a program's theming and let
   Stylix supply the palette. catppuccin/nix (`modules/theme/catppuccin.nix`)
   also auto-enables its ports; where both theme an app, one target is switched
   off in `modules/theme/`.
4. **Set only what was asked for.** Do not add extra options, defaults, or
   "nice to have" settings beyond the request.
5. **Surgical edits only.** Never rewrite a whole file. Never delete content
   the task didn't ask you to remove, including commented-out code and
   disabled options.
6. **Public repo.** No passwords, API keys, tokens, or secrets.
7. **No agent attribution in commits.** Commits you make use the repo's
   configured git identity (the user's), and every commit message or PR
   description carries no `Co-Authored-By:` trailer, no "Generated with"
   line, and no mention of Claude or any agent. The user is the sole author
   of every commit. Messages use Conventional Commits: `type(scope): subject`
   (feat, fix, refactor, perf, docs, chore, revert; scope is the repo area,
   e.g. hyprland, moku, flake) plus a bullet body saying what and why.
8. **No desktop screenshots without permission.** Never capture the screen,
   a window, or the desktop unless the user has said yes to that specific
   capture first.

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

`hostConfig` (from `hosts/<host>/settings.nix`) is threaded through
`specialArgs`, so every module can read it. Conditional imports in
`modules/home/programs/default.nix` decide what actually loads —
it is the router under `programs/`, except `gaming/default.nix`, which routes the
`gaming.*` launchers, games and tools, and `audio/guitar/default.nix`, which
routes the guitar apps. Most subdirectories are flat `.nix` files, but
`browsers/{zen,mullvad,helium}/` and `media/{freetube,moku}/` each have a
`default.nix` of their own — those are multi-file module bundles, not routers,
so a new toggle's import still goes in `programs/default.nix` (or
`programs/gaming/default.nix` for a `gaming.*` app). A new guitar app's import
goes in `audio/guitar/default.nix`, and its toggle joins that folder's gate in
`programs/default.nix`.

| Scope | Path |
| --- | --- |
| Shared user config | `modules/home/` |
| Shared system config | `modules/nixos/` |
| Per-host toggles | `hosts/{desktop,laptop}/settings.nix` |

**Desktop and laptop hostConfig stay symmetrical.** Every toggle you add goes
in both files with the same value unless told otherwise.

## Adding an application

1. Add the toggle to **both** host configs, in the group it belongs to
2. Create the module under `modules/home/programs/<group>/`.
   Check for a home-manager module first (see above) — prefer
   `programs.<pkg>.enable` over `home.packages = [pkgs.<pkg>]`
3. Add the conditional import to `programs/default.nix`:
   ```nix
   ++ lib.optionals hostConfig.media.foo [./media/foo.nix]
   ```
   The conditional belongs in `default.nix`. Do **not** wrap the module body
   in `lib.mkIf` instead.
4. `alejandra .`, `git add` the new file, `nix flake check`
5. Give any prose the task wrote or edited a cut-only revision pass before
   handing back: remove words, add none. No new information, no new claims.
   See **Writing style**.
6. Add it to the matching list under **Components** in `README.md`, including
   the link reference definition at the bottom of that file

   **`README.md` is ~32 KB — never read it in full.** Locate the two regions
   you need with grep, then edit those lines directly:

   ```bash
   grep -n '^| \*\*' README.md          # the Components table rows
   grep -n '^\[.*\]: http' README.md    # the link-reference block
   ```

   **Never add a `---` horizontal rule to `README.md`.** Zed's markdown preview
   pairs `---` lines across the file like front-matter delimiters, so the section
   after every odd-numbered rule renders as a raw code block. The file stays valid
   CommonMark and GitHub renders it fine, so the preview pane is not a reliable
   check. Section breaks come from the `##` heading alone.

## Todo notes

Planned work lives under `docs/todo/`, one file per task, named after it
(`todo/affinity-setup.md`). **When the user says "add X to the todo", write a
new file there** holding what the task is, why they want it, what the repo
already has toward it, the steps left, and any research already done (links,
versions, gotchas). Update the file rather than starting a second one for the
same task, and delete it once the work is done. These are working notes: no
`README.md` or Components entry.

## Formatting

Every module opens with a banner. **Copy it byte-for-byte from a neighbouring
module in the same directory** — note the trailing `#` closing both rule lines:

```nix
#=====================================================================#
# VIDEO TRIMMER
#=====================================================================#
{pkgs, ...}: {
  home.packages = [pkgs.video-trimmer];
}
```

Only take the arguments you use: a module that sets no packages does not need
`pkgs`.

Comments are short and explain *why*, not *what*. No session narrative, no
restating the code, no listing alternatives that were not chosen.
Keep comment lines within 89 columns (trailing comments too); shorten the
wording or move the comment above the code.

## Writing style

For replies, `README.md`, `docs/` and commit messages. Code comments are
covered under **Formatting** above.

- Lead with the answer. No "Great question", no exclamation marks, no closing
  line praising the work, no restating the request first.
- Say it once and directly. Not "it's not X, it's Y", not "not just X, but Y".
- Write full sentences, and vary their length. No fragments for emphasis, no
  run of clipped sentences.
- Don't rate the thing you are describing. "Stylix sets the palette", not
  "Stylix ensures a consistent look across every application".
- Cut a sentence that adds no information, and any list padded to three.
- Pet words: delve, robust, seamless, leverage, crucial, ensure, streamline,
  elegant, powerful, utilize, showcase, landscape, essentially, furthermore,
  tapestry, testament, pivotal, foster, enhance, cutting-edge, world-class.
  Same for any word used twice in a short passage.
- Use contractions and plain words.
- No em dashes inside a sentence in `README.md` or `docs/`; use a colon, a
  comma, parentheses, or two sentences. A dash separating a label from its
  description in a list (`` `path/` — what it holds ``) is structure and stays.
- In `docs/`, give absolute dates and versions (not "recently"), name the
  condition behind a "sometimes", and cite where a claim came from.

Prose only. Code blocks, command output, quotes and table cells are left
alone.

## Working efficiently

- **Read each file once.** Do not re-read a file unless you edited it since.
- Read only what the task needs. Two or three sibling modules are enough to
  learn a pattern.
- Batch independent shell commands into one call rather than one per step.
