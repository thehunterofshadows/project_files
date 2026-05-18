# AGENTS.md — Coding Agent Guide

This repository ([thehunterofshadows/project_files](https://github.com/thehunterofshadows/project_files)) is a self-contained `project_files/` directory of reusable bash scripts that can be cloned into any project to provide a common set of development tools.

---

## Purpose

These scripts are designed to live inside `project_files/` at the root of a host project. Keeping every repository file in that one subdirectory avoids conflicts with files the host project already has.

**Clone this repo into the host project as `project_files/`:**
```bash
git clone https://github.com/thehunterofshadows/project_files.git project_files
chmod +x project_files/*.sh 2>/dev/null || true
```

**Or install via curl tar extract into `project_files/`:**
```bash
mkdir -p project_files
curl -fsSL "https://codeload.github.com/thehunterofshadows/project_files/tar.gz/refs/heads/main" \
  | tar -xz --strip-components=1 -C project_files
chmod +x project_files/*.sh 2>/dev/null || true
```

---

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `project_files/checkpoint.sh` | Creates a git checkpoint/snapshot archive |
| `project_files/claude_run.sh` | Launches Claude AI coding assistant |
| `project_files/clean.sh` | Cleans up build artifacts and temp files |
| `project_files/docker_deploy.sh` | Deploys the project via Docker |
| `project_files/docker_visual_run.sh` | Provides reusable visual status helpers for Docker scripts |
| `project_files/filewatch.sh` | Watches files for changes and triggers actions |
| `project_files/git_sync.sh` | Syncs local repo with remote |
| `project_files/prod_clean.sh` | Cleans production environment |
| `project_files/prod_send.sh` | Deploys/sends files to production |
| `project_files/pull_tools.sh` | Pulls the latest version of these tools into `project_files/` |
| `project_files/push_clean.sh` | Cleans up before a git push |
| `project_files/restore.sh` | Restores from a checkpoint or backup |
| `project_files/setup_git.sh` | Configures git settings for a project |
| `project_files/tmux_start.sh` | Starts a tmux session with a standard layout |

---

## How to Update This Repo

When asked to add, modify, or remove scripts:

1. **Adding a new script** — Create the `.sh` file inside `project_files/`. Make sure it is self-contained and portable. Add an entry to the Scripts Overview table in this file.
2. **Modifying a script** — Edit the file directly in `project_files/`. Update its description in the table if the purpose changes.
3. **Removing a script** — Delete the file from `project_files/` and remove its row from the table.
4. **Always keep this file in sync** — The Scripts Overview table should always reflect the actual `.sh` files present in `project_files/`.

---

## Conventions

- **All repository files live in `project_files/`** — scripts, `README.md`, `AGENTS.md`, and `.env_temp` are intentionally kept there to avoid conflicts with the host project.
- **The repo root stays empty except for `project_files/`** — do not add root-level files unless explicitly asked.
- **Scripts must be portable bash** — avoid platform-specific assumptions; prefer `/usr/bin/env bash` shebangs.
- **Scripts operate on the caller's project root** — set `PROJECT_ROOT="$(pwd)"` near the top of each script and use paths relative to that current working directory.
- **Do not anchor project paths to the script directory** — avoid `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` for project file operations.
- **Scripts should be self-documenting** — include a comment block at the top of each script explaining what it does, any required environment variables, and usage examples.
- **No secrets in scripts** — use `.env` files or environment variables for credentials. The `project_files/.env_temp` file in this repo is a template; never commit real credentials.
- **Executable bit** — scripts should be committed with the executable bit set (`chmod +x`).

---

## Environment Variables

Scripts may rely on a `.env_project_tools` file in the host project root. See `project_files/.env_temp` for expected variables. Copy and populate it locally as needed, but never commit real credentials.

---

## Notes for Agents

- Read `project_files/AGENTS.md` first before making any changes to the repo.
- When adding a new script, also update the **Scripts Overview** table above.
- Do not reorganize files out of `project_files/` unless explicitly asked.
- Prefer editing existing scripts over creating new ones when the functionality overlaps.
- Commit messages should be concise and descriptive (e.g., `Add deploy_staging.sh for staging environment`).
