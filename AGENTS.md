# AGENTS.md — Coding Agent Guide

This repository ([thehunterofshadows/project_files](https://github.com/thehunterofshadows/project_files)) is a self-contained set of reusable bash scripts that should be cloned as a host project's `project_files/` directory.

---

## Purpose

These scripts are stored at this repository's root so cloning the repository into a host project as `project_files/` produces `./project_files/*.sh`, not `./project_files/project_files/*.sh`. `README_projectfiles.md` is intentionally named to avoid conflicting with a host project's own `README.md`, and `project_files_cleanup.sh` removes legacy root-level copies from projects that used the old layout.

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
| `project_files/project_files_cleanup.sh` | Removes legacy root-level tool files from a host project |

---

## How to Update This Repo

When asked to add, modify, or remove scripts:

1. **Adding a new script** — Create the `.sh` file at the repository root. Make sure it is self-contained and portable. Add an entry to the Scripts Overview table in this file.
2. **Modifying a script** — Edit the root-level script directly. Update its description in the table if the purpose changes.
3. **Removing a script** — Delete the root-level script and remove its row from the table.
4. **Always keep this file in sync** — The Scripts Overview table should always reflect the actual `.sh` files present at the repository root.

---

## Conventions

- **Tooling files live at the repository root** — this prevents a nested `project_files/project_files/` directory after cloning.
- **The README is `README_projectfiles.md`** — this is intentionally renamed from `README.md` to avoid conflicts with a host project if copied manually.
- **The cleanup helper is `project_files_cleanup.sh`** — run it from a host project as `./project_files/project_files_cleanup.sh` to remove old root-level tool files from projects that used the legacy layout.
- **The repo root is the install payload** — do not add an inner `project_files/` directory unless explicitly asked.
- **Scripts must be portable bash** — avoid platform-specific assumptions; prefer `/usr/bin/env bash` shebangs.
- **Scripts operate on the caller's project root** — set `PROJECT_ROOT="$(pwd)"` near the top of each script and use paths relative to that current working directory.
- **Do not anchor project paths to the script directory** — avoid `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` for project file operations.
- **Scripts should be self-documenting** — include a comment block at the top of each script explaining what it does, any required environment variables, and usage examples.
- **No secrets in scripts** — use `.env` files or environment variables for credentials. The `.env_temp` file in this repo is a template; never commit real credentials.
- **Executable bit** — scripts should be committed with the executable bit set (`chmod +x`).

---

## Environment Variables

Scripts may rely on a `.env_project_tools` file in the host project root. See `.env_temp` for expected variables. Copy and populate it locally as needed, but never commit real credentials.

---

## Notes for Agents

- Read `AGENTS.md` first before making any changes to the repo.
- When adding a new script, also update the **Scripts Overview** table above.
- Do not add a nested `project_files/` directory unless explicitly asked.
- Prefer editing existing scripts over creating new ones when the functionality overlaps.
- Commit messages should be concise and descriptive (e.g., `Add deploy_staging.sh for staging environment`).
