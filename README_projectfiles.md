# project_files

Reusable project tooling scripts are kept at this repository's root so the repository can be cloned directly into an existing project's `project_files/` directory.

## Install

Clone this repository directly as the `project_files/` folder in your project root:

```bash
git clone https://github.com/thehunterofshadows/project_files.git project_files
chmod +x project_files/*.sh 2>/dev/null || true
```

Or install from the main branch tarball:

```bash
mkdir -p project_files
curl -fsSL "https://codeload.github.com/thehunterofshadows/project_files/tar.gz/refs/heads/main" \
  | tar -xz --strip-components=1 -C project_files
chmod +x project_files/*.sh 2>/dev/null || true
```

## Usage

Run scripts from your project root:

```bash
./project_files/clean.sh
./project_files/docker_deploy.sh
./project_files/tmux_start.sh
```

Scripts use the caller's current working directory as the project root via:

```bash
PROJECT_ROOT="$(pwd)"
```

They do not anchor project paths to the script's own location.

## Legacy Cleanup

If a project still has the old root-level copies of these tools, run:

```bash
./project_files/project_files_cleanup.sh
```

Preview the cleanup first with:

```bash
./project_files/project_files_cleanup.sh --dry-run
```

The cleanup removes known legacy root-level tool scripts. It only removes root `README.md`, `AGENTS.md`, and `.env_temp` when they look like files from this repository.

## Scripts

| Script | Purpose |
|--------|---------|
| `project_files/checkpoint.sh` | Creates a checkpoint archive for the current project |
| `project_files/claude_run.sh` | Launches Claude AI coding assistant |
| `project_files/clean.sh` | Cleans up build artifacts and Docker state |
| `project_files/docker_deploy.sh` | Syncs git changes and rebuilds Docker with visual status |
| `project_files/docker_visual_run.sh` | Shared visual step runner for Docker scripts |
| `project_files/filewatch.sh` | Watches files for changes and displays recent updates |
| `project_files/git_sync.sh` | Commits and pushes local repo changes |
| `project_files/prod_clean.sh` | Cleans and rebuilds production Docker environment |
| `project_files/prod_send.sh` | Deploys a selected checkpoint to production |
| `project_files/pull_tools.sh` | Pulls the latest version of these tools into `project_files/` |
| `project_files/push_clean.sh` | Runs git push and `project_files/clean.sh` in parallel |
| `project_files/restore.sh` | Restores from a checkpoint archive |
| `project_files/setup_git.sh` | Configures git user settings |
| `project_files/tmux_start.sh` | Starts a tmux session with a standard layout |
| `project_files/project_files_cleanup.sh` | Removes legacy root-level tool files from a host project |

## Environment

Use a `.env_project_tools` file in the host project root for tool-specific configuration. `project_files/.env_temp` is only a template and should not contain real credentials.
