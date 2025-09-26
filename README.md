Dev Container and Unified Setup

Overview
- Provides a ready-to-use dev container based on `mcr.microsoft.com/devcontainers/base:ubuntu`.
- Consolidates host setup into one idempotent script (`scripts/bootstrap.sh`).
- Adds a helper to manage the container lifecycle (`scripts/devcontainer.sh`).

Repo contents
- `Dockerfile`: Installs zsh, Oh My Zsh (unattended), zsh plugins, fzf, autojump, thefuck, Node.js 18, Go 1.18.
- `docker-compose.yml`: Defines service `dev`; mounts repo at `/workspaces/.dotfiles`; starts `zsh`.
- `scripts/bootstrap.sh`: One-shot Ubuntu setup (zsh + tooling), safe to re-run.
- `scripts/devcontainer.sh`: Helper CLI to build/run/exec the dev container with configurable parameters.
- Legacy: `install.sh`, `initzsh.sh` (replaced by `bootstrap.sh`).

Why consolidate
- Previous flow required alternating scripts and manual confirmations.
- New flow defines strict order, removes prompts, and captures dependencies.

Setup order (dependencies)
- System packages → default shell zsh → Oh My Zsh + plugins → fzf → helpers (thefuck, autojump) → Node 18 → Go 1.18 → shell env + dotfiles.

Quick start (docker compose)
- Start: `docker compose up --build -d`
- Attach: `docker exec -it dotfiles-dev zsh`
- Stop: `docker compose down`

Helper script (recommended)
- Make executable: `chmod +x scripts/devcontainer.sh`
- Start: `scripts/devcontainer.sh up`
- Rebuild: `scripts/devcontainer.sh rebuild --no-cache`
- Stop: `scripts/devcontainer.sh down`
- Exec: `scripts/devcontainer.sh exec` (opens zsh) or `scripts/devcontainer.sh exec node -v`

Configurable parameters
- Build args (Dockerfile/compose):
  - `BASE_IMAGE` (default `mcr.microsoft.com/devcontainers/base:ubuntu`)
  - `NODE_MAJOR` (default `18`)
  - `GO_VERSION` (default `1.18.10`)
- Compose vars:
  - `IMAGE_NAME` (default `dotfiles-dev`)
  - `CONTAINER_NAME` (default `dotfiles-dev`)
  - `TZ` (default `UTC`)
  - SSH mount: `${HOME}/.ssh:/home/vscode/.ssh:ro` (read-only)
- In `scripts/devcontainer.sh` the above can be set via flags, e.g.:
  - `scripts/devcontainer.sh up --node 20 --go 1.22.5 --base ubuntu:24.04 --project dotfiles2 --container-name dotfiles-dev-2`

Multiple instances
- Option A: Keep `container_name` and pass a unique `--container-name` and `--project` to the helper.
- Option B: Remove `container_name` in compose file, then use different `-p/--project` to run multiple stacks.

Host setup (optional)
- For Ubuntu hosts, run: `chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh`
- This installs zsh, Oh My Zsh, plugins, Node 18, Go 1.18 and updates `.zshrc` idempotently.

Notes
- thefuck alias in `.zshrc` is guarded; shell won’t break if its Python deps change.
- Inside container, login shell is zsh; non-interactive exec may show `SHELL=/bin/bash`, which is expected.
- Node/Go versions can be overridden at build time; `scripts/devcontainer.sh` forwards build args.
