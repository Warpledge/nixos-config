# AGENTS.md

## Critical: Read CLAUDE.md first

**Always read `CLAUDE.md` at the start of every session.** It contains the full
repo rules, architecture, workflows, and critical gotchas. This AGENTS.md is
OpenCode-specific tips only; CLAUDE.md has everything else. Read it before
doing any work.

## Context budget

Your context window is 128K tokens and the tool definitions already use about
27K of it. Long tasks get compacted, and whatever you only held in context is
lost. Work so that compaction costs nothing:

- **Start every multi-step task with a todo list** (the `todowrite` tool), one
  item per file or step, and tick items off as you go. After a compaction, read
  the todo list and run `git status --short && git diff --stat` to see where you
  are. Do not re-read files to rebuild your memory.
- **Never read a large file whole.** `README.md` (~38 KB) is off limits in full:
  `grep -n` for the lines you need, then read that range with an offset and
  limit. Do the same for any file over ~300 lines.
- **Read each file once**, and only the files the task touches. Two or three
  sibling modules are enough to learn a pattern.
- **Trim command output at the source**: `nix flake check 2>&1 | tail -n 30`,
  `alejandra <file> 2>&1 | tail -n 5`, man pages through `grep`. Never print a store
  listing, a derivation or a full log.
- **Checkpoint on demand.** When the user asks "where are we?" or "summarize", output a brief status (what's done, what's blocking, next step) and wait for direction instead of continuing.
- **Small edits.** Use the edit tool with the shortest unique `oldString`, not a
  whole-file write. Finish one file before opening the next.
- **Batch** independent shell commands into one call.
- **Don't think in circles.** Once you know the next step, take it. If the same tool fires on the same path twice without new information, stop and try a different approach. If you're unsure how to proceed, stop and ask instead of looping.

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

Read them this way:

- `<skill-dir>` is `modules/home/programs/ai/skills/<name>`, so run
  `bash modules/home/programs/ai/skills/add-app/scripts/check-app.sh ...`.
- "CLAUDE.md rule 1" is rule 1 in `CLAUDE.md` (no rebuilds, when to flake check);
  "rule 6" is rule 7 there (commit format). You already read it at session start
  (see above). If a skill names a CLAUDE.md section you need, `grep -n` it.
- A step that hands work to a subagent (`public-repo-auditor`,
  `prose-reviewer`, `build-triager`, `docs-drift-auditor`) is yours to do:
  for the auditor, read `git diff --cached` for personal data, private paths,
  hostnames and tokens; for the prose pass, cut words from what you wrote.
