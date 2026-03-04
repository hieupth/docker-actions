#!/bin/bash
set -euo pipefail

# === PARSE INPUTS ===
IMAGE="${INPUT_IMAGE:-}"
RUN="${INPUT_RUN:-}"
SHELL="${INPUT_SHELL:-bash}"
OPTIONS="${INPUT_OPTIONS:-}"
WORKDIR="${INPUT_WORKDIR:-}"
ENV_INPUT="${INPUT_ENV:-}"
CLEANUP="${INPUT_CLEANUP:-true}"
DRY_RUN="${INPUT_DRY_RUN:-false}"
CONTAINER_NAME="${INPUT_CONTAINER_NAME:-}"
DOCKER_NETWORK="${INPUT_DOCKER_NETWORK:-}"

# Validate required inputs
if [[ -z "$IMAGE" ]]; then
  echo "ERROR: 'image' input is required" >&2
  exit 1
fi

# === BUILD DOCKER RUN COMMAND ===

# Base flags
FLAGS=()

# Cleanup flag
if [[ "$CLEANUP" == "true" ]]; then
  FLAGS+=("--rm")
fi

# Container name (store in variable to avoid ${RANDOM} mismatch in logs)
if [[ -n "$CONTAINER_NAME" ]]; then
  ACTUAL_CONTAINER_NAME="$CONTAINER_NAME"
else
  ACTUAL_CONTAINER_NAME="inside-container-${RANDOM}"
fi
FLAGS+=("--name" "$ACTUAL_CONTAINER_NAME")

# Shell entrypoint
FLAGS+=("--entrypoint" "$SHELL")

# Docker-in-Docker mounts
FLAGS+=(
  -v "/var/run/docker.sock":"/var/run/docker.sock"
  -v "/usr/bin/docker":"/usr/bin/docker"
  -v "/usr/libexec/docker/cli-plugins":"/usr/libexec/docker/cli-plugins"
)

# Working directory
if [[ -n "$WORKDIR" ]]; then
  FLAGS+=("-w" "$WORKDIR")
fi

# Environment variables
if [[ -n "$ENV_INPUT" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && FLAGS+=("-e" "$line")
  done <<< "$ENV_INPUT"
fi

# Docker network
if [[ -n "$DOCKER_NETWORK" ]]; then
  FLAGS+=("--network" "$DOCKER_NETWORK")
fi

# User options (support both single-line and multi-line forms)
if [[ -n "$OPTIONS" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -ra OPTS_ARRAY <<< "$line"
    FLAGS+=("${OPTS_ARRAY[@]}")
  done <<< "$OPTIONS"
fi

# TTY support
FLAGS+=("-it")

# === EXECUTE ===
echo "INFO: Running inside container: $IMAGE"
echo "INFO: Container name: $ACTUAL_CONTAINER_NAME"
echo "INFO: Docker network: ${DOCKER_NETWORK:-default}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "INFO: Dry run enabled, skipping docker run"
  exit 0
fi

# Multi-line command handling
CMD="${RUN//$'\n'/;}"

exec docker run "${FLAGS[@]}" "$IMAGE" -c "$CMD"
