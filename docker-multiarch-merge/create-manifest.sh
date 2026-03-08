#!/bin/bash
set -euo pipefail

IMAGE="${INPUT_IMAGE:?ERROR: image input is required}"
TAG="${INPUT_TAG:?ERROR: tag input is required}"
DIG="${INPUT_DIGESTS_PATH:-/tmp/digests}"

shopt -s nullglob
files=("$DIG"/*.digest)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "ERROR: no digest files found in $DIG" >&2
  exit 1
fi

IMAGES=()
for f in "${files[@]}"; do
  d="$(cat "$f")"
  # Validate digest format (sha256:64 hex chars)
  if [[ ! "$d" =~ ^sha256:[a-fA-F0-9]{64}$ ]]; then
    echo "ERROR: Invalid digest format in $f: $d" >&2
    exit 1
  fi
  IMAGES+=("${IMAGE}@${d}")
done

# imagetools creates a manifest list from manifests that already exist in registry
# https://docs.docker.com/reference/cli/docker/buildx/imagetools/create/
docker buildx imagetools create -t "${IMAGE}:${TAG}" "${IMAGES[@]}"
docker buildx imagetools inspect "${IMAGE}:${TAG}"
