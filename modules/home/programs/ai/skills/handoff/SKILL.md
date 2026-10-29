---
name: handoff
description: Write a handoff note so a fresh session can continue this one, or pick up the waiting note. Use when the user says to hand off, wrap up for a new chat, or is about to /clear, instead of /compact; and in a new session when the user says "continue", "pick up where we left off" or the session-start hint names a waiting handoff.
argument-hint: "resume" to pick up the waiting note; anything else is a focus for the note
---

# Handoff

Notes live in `.claude/handoffs/` at the repo root (gitignored). A waiting note sits at the
top level; a picked-up one moves to `.claude/handoffs/done/`. The session-start hook
(`modules/home/programs/ai/hooks/session-start.sh`) names waiting notes in a new session.

## Write (default)

1. Run `git status --short` and `git log --oneline -10` so the note can point at commits
   instead of repeating them.
2. Write `.claude/handoffs/<YYYY-MM-DD-HHMM>-<short-slug>.md` (date from `date +%F-%H%M`),
   at most about 50 lines, in this shape:

   ```markdown
   # <task in a few words>

   **Goal:** what the user wants overall, in their terms.

   **Done:** one bullet per finished piece, with its commit hash.

   **Decisions:** what the user chose and why, including options they turned down,
   so the next session doesn't ask again.

   **State:** uncommitted changes, a rebuild still to run, anything half-done.

   **Next:** numbered steps, the first one ready to start.

   **Open questions:** what still needs the user's answer.

   **Files:** the paths the next session should read first.
   ```

   Write facts the repo can't show: the user's preferences, decisions and their reasons,
   dead ends. Don't paste diffs, file contents or tool output. Use the argument, if any,
   as the focus.
3. Tell the user the path and that they can `/clear` now; the next session gets a hint
   and they can say "continue".

## Resume (argument `resume`, or the user says continue)

1. `ls .claude/handoffs/*.md`. With several, take the newest unless the user named one.
2. Read it, then move it: `mkdir -p .claude/handoffs/done && mv <note> .claude/handoffs/done/`.
3. Give the user a two-line summary (goal, first next step) and start on **Next** unless
   an open question blocks it; ask that first.
