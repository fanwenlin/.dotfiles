#!/usr/bin/env bash
set -euo pipefail

# A small helper to build/run the dev container with sensible defaults.

# Defaults (can be overridden by env or flags)
PROJECT=${PROJECT:-dotfiles}
IMAGE_NAME=${IMAGE_NAME:-dotfiles-dev}
CONTAINER_NAME=${CONTAINER_NAME:-dotfiles-dev}
BASE_IMAGE=${BASE_IMAGE:-mcr.microsoft.com/devcontainers/base:ubuntu}
NODE_MAJOR=${NODE_MAJOR:-22}
GO_VERSION=${GO_VERSION:-1.23.2}
TZ=${TZ:-UTC}

COMPOSE="docker compose"

usage() {
  cat <<USAGE
Usage: scripts/devcontainer.sh <command> [options]

Commands
  up                Build (if needed) and start in background
  rebuild           Force rebuild without cache and restart
  down              Stop and remove containers (use --volumes to drop volumes)
  ps                Show compose services status
  logs              Tail logs (Ctrl-C to stop)
  exec [cmd]        Exec inside container (default: zsh)

Options
  -p, --project NAME          Compose project name (default: ${PROJECT})
      --image-name NAME       Image name (default: ${IMAGE_NAME})
      --container-name NAME   Container name (default: ${CONTAINER_NAME})
      --base IMAGE            Base image (default: ${BASE_IMAGE})
      --node MAJOR            Node major version (default: ${NODE_MAJOR})
      --go VERSION            Go version (default: ${GO_VERSION})
      --tz TZ                 Timezone (default: ${TZ})
      --no-cache              Build without cache (rebuild/recreate)
      --volumes               With 'down', also remove named/anonymous volumes
  -h, --help                  Show this help

Notes
  - Multiple instances: set a different --project and --container-name.
  - Build args are passed through to Dockerfile via compose build.
USAGE
}

cmd=${1:-}
shift || true

NO_CACHE=false
WITH_VOLUMES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project) PROJECT="$2"; shift 2;;
    --image-name) IMAGE_NAME="$2"; shift 2;;
    --container-name) CONTAINER_NAME="$2"; shift 2;;
    --base) BASE_IMAGE="$2"; shift 2;;
    --node) NODE_MAJOR="$2"; shift 2;;
    --go) GO_VERSION="$2"; shift 2;;
    --tz) TZ="$2"; shift 2;;
    --no-cache) NO_CACHE=true; shift;;
    --volumes) WITH_VOLUMES=true; shift;;
    -h|--help) usage; exit 0;;
    *) break;;
  esac
done

if [[ -z "${cmd}" ]]; then
  usage; exit 1
fi

export IMAGE_NAME CONTAINER_NAME BASE_IMAGE NODE_MAJOR GO_VERSION TZ

compose() {
  ${COMPOSE} -p "${PROJECT}" "$@"
}

build_args=(
  --build-arg BASE_IMAGE="${BASE_IMAGE}"
  --build-arg NODE_MAJOR="${NODE_MAJOR}"
  --build-arg GO_VERSION="${GO_VERSION}"
)

case "$cmd" in
  up)
    if $NO_CACHE; then
      compose build --no-cache "${build_args[@]}"
    else
      compose build "${build_args[@]}"
    fi
    compose up -d
    ;;
  rebuild)
    compose build --no-cache "${build_args[@]}"
    compose up -d
    ;;
  down)
    if $WITH_VOLUMES; then
      compose down -v
    else
      compose down
    fi
    ;;
  ps)
    compose ps
    ;;
  logs)
    compose logs -f
    ;;
  exec)
    if [[ $# -gt 0 ]]; then
      compose exec dev "$@"
    else
      compose exec dev zsh
    fi
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac

