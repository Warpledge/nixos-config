# Back up the personal mod projects to private GitHub repos

**Goal:** every personal mod project under `~/Projects` has a private GitHub repo to push to, so a lost disk doesn't lose the work. Craft Chain first: it has 21 commits and no remote at all. Creating the repos and pushing stay with the user.

Added 2026-11-21.

## What's already in the repo

Nothing; the projects live outside this repo. Their state on 2026-11-21 (`git remote -v`, `git branch`, `ls`):

| Project | Remote | Branches | LICENSE / NOTICE |
| --- | --- | --- | --- |
| `craftchain` | done 2026-11-21: private `Warpledge/craftchain`, votex09 has write | `main` | both (NOTICE credits GTNH Planner, MIT) |
| `ezminer-balanced` | `origin` = upstream `czqwq/EZMiner` | `balanced`, `master` | LICENSE |
| `ezstorage-craftfix` | none | `main` | LICENSE |
| `gtnh-translation-agent` | none | `main` | none |
| `omni-tweaks` | none | `main` | LICENSE |
| `smoothswapping` | none | `main` | both |
| `touhoulittlemaid-gtnh` | none | `main` | none |

## Steps

1. Per project, check for secrets before the first push: `git log -p | grep -iE "token|api[_-]?key|password|secret"`, plus any config or `.env` file. A private repo still copies history to GitHub.
2. Decide the licence for the two without one (`gtnh-translation-agent`, `touhoulittlemaid-gtnh`). A port of someone else's mod keeps their licence; check its upstream first.
3. Create each repo private and push every branch, from inside the project:

   ```bash
   gh repo create Warpledge/craftchain --private --source . --remote origin --push
   git push origin --all
   ```

4. `ezminer-balanced` already has `origin` pointing at upstream. Add the backup as a second remote instead of replacing it, so upstream pulls keep working:

   ```bash
   gh repo create Warpledge/ezminer-balanced --private --source . --remote backup
   git push backup --all
   ```

5. Afterwards, push after each commit worth keeping (or add a post-commit hook that pushes, if wanted).

`gh repo create` flags (`--private`, `--source`, `--remote`, `--push`) are from `gh repo create --help`.
