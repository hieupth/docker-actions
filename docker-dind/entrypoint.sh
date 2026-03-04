#!/bin/bash
set -euo pipefail

# === PARSE INPUTS ===
IMAGE="${INPUT_IMAGE}"
RUN="${INPUT_RUN}"
SHELL="${INPUT_SHELL:-bash}"
OPTIONS="${INPUT_OPTIONS:-}"
WORKDIR="${INPUT_WORKDIR:-}"
ENV_INPUT="${INPUT_ENV:-}"
CLEANUP="${INPUT_CLEANUP:-true}"
CONTAINER_NAME="${INPUT_CONTAINER_NAME:-}"
DOCKER_NETWORK="${INPUT_DOCKER_NETWORK:-}"

# === BUILD DOCKER RUN COMMAND ===

# Base flags
FLAGS=()

# Cleanup flag
if [[ "$CLEANUP" == "true" ]]; then
  FLAGS+=("--rm")
fi

# Container name
if [[ -n "$CONTAINER_NAME" ]]; then
  FLAGS+=("--name" "$CONTAINER_NAME")
else
  FLAGS+=("--name" "inside-container-${RANDOM}")
fi

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

# User options
if [[ -n "$OPTIONS" ]]; then
  # shellcheck disable=SC2206
  OPTS_ARRAY=($OPTIONS)
  FLAGS+=("${OPTS_ARRAY[@]}")
fi

# TTY support
FLAGS+=("-it")

# === EXECUTE ===
echo "INFO: Running inside container: $IMAGE"
echo "INFO: Container name: ${FLAGS[2]}"

# Multi-line command handling
CMD="${RUN//$'\n'/;}"

exec docker run "${FLAGS[@]}" "$IMAGE" -c "$CMD"
