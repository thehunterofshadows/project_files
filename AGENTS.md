# AGENTS.md — Coding Agent Guide

This repository ([thehunterofshadows/project_files](https://github.com/thehunterofshadows/project_files)) is a collection of reusable bash scripts that can be pulled into any project to provide a common set of development tools.

---

## Purpose

These scripts are designed to be dropped into the root of any project. They provide standardized tooling for common development tasks so every project gets the same reliable workflow without reinventing the wheel.

**Install all scripts into the current directory:**
```bash
repo="thehunterofshadows/project_files"
branch="main"
curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$branch" \
  | tar -xz --wildcards --strip-components=1 '*/*.sh'
chmod +x ./*.sh 2>/dev/null || true
```

---

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `checkpoint.sh` | Creates a git checkpoint/snapshot commit |
| `claude_run.sh` | Launches Claude AI coding assistant |
| `clean.sh` | Cleans up build artifacts and temp files |
| `docker_deploy.sh` | Deploys the project via Docker |
| `docker_visual_run.sh` | Runs Docker with visual/GUI support |
| `filewatch.sh` | Watches files for changes and triggers actions |
| `git_sync.sh` | Syncs local repo with remote |
| `prod_clean.sh` | Cleans production environment |
| `prod_send.sh` | Deploys/sends files to production |
| `pull_tools.sh` | Pulls the latest version of these tools into a project |
| `push_clean.sh` | Cleans up before a git push |
| `restore.sh` | Restores from a checkpoint or backup |
| `setup_git.sh` | Configures git settings for a project |
| `tmux_start.sh` | Starts a tmux session with a standard layout |

---

## How to Update This Repo

When asked to add, modify, or remove scripts:

1. **Adding a new script** — Create the `.sh` file in the repo root. Make sure it is self-contained and portable. Add an entry to the Scripts Overview table in this file.
2. **Modifying a script** — Edit the file directly. Update its description in the table if the purpose changes.
3. **Removing a script** — Delete the file and remove its row from the table.
4. **Always keep this file in sync** — The Scripts Overview table should always reflect the actual `.sh` files present in the repo root.

---

## Conventions

- **All scripts live in the repo root** — no subdirectories for scripts.
- **Scripts must be portable bash** — avoid platform-specific assumptions; prefer `/usr/bin/env bash` shebangs.
- **Scripts should be self-documenting** — include a comment block at the top of each script explaining what it does, any required environment variables, and usage examples.
- **No secrets in scripts** — use `.env` files or environment variables for credentials. The `.env_temp` file in this repo is a template; never commit real credentials.
- **Executable bit** — scripts should be committed with the executable bit set (`chmod +x`).

---

## Environment Variables

Scripts may rely on a `.env` file in the project root. See `.env_temp` for the expected variables. Copy and populate it locally — never commit a populated `.env` file.

---

## Notes for Agents

- Read this file first before making any changes to the repo.
- When adding a new script, also update the **Scripts Overview** table above.
- Do not reorganize the repo structure (no subdirectories for scripts) unless explicitly asked.
- Prefer editing existing scripts over creating new ones when the functionality overlaps.
- Commit messages should be concise and descriptive (e.g., `Add deploy_staging.sh for staging environment`).
