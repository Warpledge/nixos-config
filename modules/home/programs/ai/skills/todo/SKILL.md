---
name: todo
description: Write, update or close a planned-work note in this repo's docs/todo/. Use when the user says "add X to the todo", asks to note something for later, asks what's on the todo list, or finishes work that a docs/todo/ file tracks.
---

# Todo notes

Planned work lives in `docs/todo/`, one file per task, named after it in kebab case
(`docs/todo/affinity-setup.md`). These are working notes: no `README.md` row or
Components entry.

## Add

1. `ls docs/todo/` and check whether a file already covers the task. If one does,
   update it instead of starting a second.
2. Write `docs/todo/<task>.md`, following the existing ones (`gpu-undervolt.md` is
   a full example):
   - `# Title`, then a `**Goal:**` line: what the task is and why the user wants it
   - `Added <YYYY-MM-DD>.`
   - `## What's already in the repo`: the files and options that exist toward it
   - the steps left
   - any research already done: links, versions, gotchas, each with its source
3. Follow **Writing Style** in CLAUDE.md: pin time-bound facts to a date or version,
   no em dashes.

`quick-todos.md` is the user's own list of one-line items; add to it only when asked.

## Update

Change the file in place: move a done step into "What's already in the repo", add a
dated `**Status (YYYY-MM-DD):**` line, keep the research.

## Close

When the work is done, delete the file (`rm` with its absolute path, as its own
command) and commit the deletion with the work, through the `commit` skill.
