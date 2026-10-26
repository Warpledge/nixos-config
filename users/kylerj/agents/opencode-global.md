# Global rules

These apply in every project. A project's own `AGENTS.md` comes first where the two
disagree.

## This computer

- NixOS. Never run `sudo`, `nixos-rebuild` or `nixm rebuild`; tell Ky what to run.
- Don't install anything system-wide or with `pip install --user`, `npm -g` or
  `cargo install`. Run a tool once with `nix shell nixpkgs#<pkg> --command <cmd>`,
  and say if it should be added to the config for good.
- `apt`, `brew` and `/usr/bin/<tool>` paths don't exist here.

## Before acting

- Ask before anything hard to undo: deleting or overwriting files you haven't read,
  `git push`, `git reset --hard`, force-pushes, history rewrites, or sending anything to
  an outside service.
- Never capture the screen or a window without asking first. Images Ky gives you, and
  frames a program writes to a file, are fine.
- Never put passwords, API keys or tokens in files or commits.

## Doing the work

- Check an API, option or flag in the docs, the source or `--help` before using it.
  Don't write one from memory. Say when you aren't sure.
- After a change, run the build, tests or checker the project has, and report failures
  with their output. Don't call something done that you haven't run.
- If the same fix fails twice, stop, say what you tried and what you think is wrong,
  and ask. Don't keep retrying variations.
- Change only what was asked. Offer extras; don't add them.
- Keep edits small and in the existing style. Don't rewrite whole files.

## Replies

- Lead with the answer. Short, plain sentences; no filler, praise or exclamation marks.
- Use they/them for anyone whose pronouns you don't know.
