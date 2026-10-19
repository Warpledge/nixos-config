# AGENTS.md

NixOS flake managing two machines, **eclipse** (desktop) and **legion** (laptop), one folder
each in `machines/`, with each person's apps in `users/`. Nixpkgs unstable,
home-manager, Niri WM, Stylix theming (Catppuccin Mocha).

## Rules

1. **Never run `nixm rebuild` or `nixos-rebuild`.** Stop and ask instead.
   Run `alejandra .` after editing Nix. Run `nix flake check`, and a host
   build even more rarely, only when you can't tell whether a change breaks
   evaluation or the build (a new module or import, an unfamiliar option, an
   input or package change); a value change in a working option, or a JSON,
   Markdown or comment edit, needs neither. Commit without asking (see
   rule 7); pushing and history rewrites stay with the user.
2. **`git add` new files before `nix flake check`** — the flake ignores
   untracked files and the check fails with "file is not available".
3. **Stylix owns all theming.** Never set colors, fonts, or wallpaper in a
   module. Enable a program's theming and let Stylix supply the palette.
   catppuccin/nix (`modules/theme/catppuccin.nix`) also auto-enables its
   ports; where both theme an app, one target is switched off in
   `modules/theme/`.
4. **Set only what was asked for.** Do not add extra options, defaults, or
   "nice to have" settings beyond the request.
5. **Surgical edits only.** Never rewrite a whole file. Never delete content
   the task didn't ask you to remove, including commented-out code and
   disabled options.
6. **Public repo.** No passwords, API keys, tokens, or secrets.
7. **Commit format.** Commits you make use the repo's configured git
   identity (the user's). Messages use Conventional Commits: `type(scope): subject`
   (feat, fix, refactor, perf, docs, chore, revert; scope is the repo area,
   e.g. hyprland, moku, flake) plus a bullet body saying what and why.
8. **No desktop screenshots without permission.** Never capture the screen,
   a window, or the desktop unless the user has said yes to that specific
   capture first.

## Context budget

Your context window is 128K tokens and the tool definitions already use about
27K of it. Long tasks get compacted, and whatever you only held in context is
lost. Work so that compaction costs nothing:

- **Start every multi-step task with a todo list** (the `todowrite` tool), one
  item per file or step, and tick items off as you go. After a compaction, read
  the todo list and run `git status --short && git diff --stat` to see where you
  are. Do not re-read files to rebuild your memory.
- **Never read a large file whole.** `CLAUDE.md` (~40 KB) and `README.md`
  (~38 KB) are off limits in full: `grep -n` for the lines you need, then read
  that range with an offset and limit. Do the same for any file over ~300 lines.
- **Read each file once**, and only the files the task touches. Two or three
  sibling modules are enough to learn a pattern.
- **Trim command output at the source**: `nix flake check 2>&1 | tail -n 30`,
  `alejandra . 2>&1 | tail -n 5`, man pages through `grep`. Never print a store
  listing, a derivation or a full log.
- **Small edits.** Use the edit tool with the shortest unique `oldString`, not a
  whole-file write. Finish one file before opening the next.
- **Batch** independent shell commands into one call.
- **Don't think in circles.** Once you know the next step, take it.

## Skills

The repo's skills are loaded through the `skill` tool. When a request matches
one, load it **before** doing anything else and follow its steps; they carry
checks that are easy to miss.

| Skill | Use when |
| --- | --- |
| `add-app` | Installing, adding, enabling or packaging any app, launcher or service |
| `commit` | Every commit |
| `disable-package` | An update broke one package; switch it off or back on |
| `freetube-sync` | "I blocked more" / "sync freetube" |
| `apparmor-check` | After editing `modules/nixos/security/apparmor/` |
| `hyprland-verify` | After editing Hyprland config |
| `game-troubleshooting` | A game crashes, freezes or won't start |
| `vn-setup`, `rpgm-setup` | Upscaling a visual novel or RPG Maker game |
| `moku-bump` | Updating or repairing Moku/Tsunagu |
| `android-debloat-redo` | Tablet debloat after an OTA |
| `flake-update` | Only when the user runs `/flake-update`; never on your own |

The skills were written for Claude Code. Read them this way:

- `<skill-dir>` is `modules/home/programs/ai/skills/<name>`, so run
  `bash modules/home/programs/ai/skills/add-app/scripts/check-app.sh ...`.
- "CLAUDE.md rule 1" is rule 1 above (no rebuilds, when to flake check);
  "rule 6" is rule 7 above (commit format). Do not open `CLAUDE.md` to look
  a rule up. If a skill names a CLAUDE.md section you need, `grep -n` it.
- A step that hands work to a subagent (`public-repo-auditor`,
  `prose-reviewer`, `build-triager`, `docs-drift-auditor`) is yours to do:
  for the auditor, read `git diff --cached` for personal data, private paths,
  hostnames and tokens; for the prose pass, cut words from what you wrote.
- The context7, deepwiki and grep MCP tools are off for you. Skip steps that
  need them and use the lookups below.

## Looking things up

**Never write a package homepage, description, or option name from memory.**

| Need | Use |
| --- | --- |
| Package metadata | `nix eval --raw nixpkgs#<pkg>.meta.homepage` |
| nixpkgs / NixOS + home-manager options | the `nixos` MCP tool |
| An app's own config syntax | `nix-shell -p <pkg> --run 'man <name>' \| col -b \| grep -A3 <term>` |
| A home-manager module for a program | `find /nix/store -maxdepth 4 -path '*/modules/programs/<pkg>.nix' \| head -1` |

If the home-manager module exists, read it and use `programs.<pkg>` instead
of `home.packages`. Stop once you have the answer: a man page is
authoritative for config syntax, so don't go on to the nixpkgs derivation.
Don't guess documentation URLs; after two failed fetches, use a local source.

## Architecture

`lib/settings.nix` reads `machines/<name>/settings.nix` and the
`users/<name>/settings.nix` of each user it lists, and passes them on: NixOS
modules get `machine` (machine settings, users' final settings in
`machine.users`) and `anyUser` (each user toggle, on if any user has it); home
modules get `machine` and `user`. The two `_template/settings.nix` files list
every setting; anything a file leaves out is off. Home routers read `user` in
`imports`, so they take it as a first argument (`user: {lib, ...}: {...}`,
imported with `(import ./gaming user)`).

| Scope | Path |
| --- | --- |
| Shared user config | `modules/home/` |
| Shared system config | `modules/nixos/` |
| Machine toggles (services, kernel, WM) | `machines/<name>/settings.nix` |
| User toggles (apps) | `users/<name>/settings.nix` |
| One user's change on one machine | `users.<name>` block in `machines/<machine>/settings.nix` |
| Where a new app's import goes | `modules/home/programs/default.nix`; `gaming.*` in `programs/gaming/default.nix`; guitar apps in `audio/guitar/default.nix`, toggle added to that folder's gate in `programs/default.nix` |

`browsers/zen/`, `media/{freetube,moku}/` and `gaming/launchers/xsystem4/` have a
`default.nix` of their own, but they're module bundles, not routers. The
conditional import (`++ lib.optionals user.media.foo [./media/foo.nix]`) is
what gates a module; do **not** wrap a new module's body in `lib.mkIf` instead.

**A new toggle goes in its template first.** `users/_template/settings.nix`
(`false` unless every new user should get it) or `machines/_template/settings.nix`,
then on in `users/warpledge/settings.nix` or the machine's file, and in
`setup.sh`'s `apps` or `services` list.

**Never add a `---` line to `README.md`.** Zed's preview pairs them like
front-matter and shows the sections between as raw text.

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

For replies, `README.md`, `docs/` and commit messages.

- Lead with the answer. No "Great question", no exclamation marks, no closing
  line praising the work, no restating the request first.
- Say it once and directly. Not "it's not X, it's Y".
- Write full sentences of varied length. No fragments for emphasis.
- Don't rate the thing you are describing. "Stylix sets the palette", not
  "Stylix ensures a consistent look across every application".
- Cut a sentence that adds no information, and any list padded to three.
- Pet words to avoid: delve, robust, seamless, leverage, crucial, ensure,
  streamline, elegant, powerful, utilize, showcase, essentially, furthermore,
  pivotal, foster, enhance, cutting-edge.
- Use contractions and plain words.
- No em dashes inside a sentence in `README.md` or `docs/`. A dash separating
  a label from its description in a list is structure and stays.
- In `docs/`, give absolute dates and versions, and cite where a claim came from.
- A reply that names packages or upstream sources ends with a **Sources** list
  linking each one, taken from `meta.homepage` or the flake input's repo.

Code blocks, command output, quotes and table cells are left alone.
