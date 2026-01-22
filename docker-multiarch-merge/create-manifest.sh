#!/bin/bash
set -euo pipefail

IMAGE="${INPUT_IMAGE}"
TAG="${INPUT_TAG}"
DIG="${INPUT_DIGESTS_PATH}"

shopt -s nullglob
files=("$DIG"/*.digest)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "ERROR: no digest files found in $DIG" >&2
  exit 1
fi

IMAGES=""
for f in "${files[@]}"; do
  d="$(cat "$f")"
  IMAGES="$IMAGES ${IMAGE}@${d}"
done

# imagetools creates a manifest list from manifests that already exist in registry
# https://docs.docker.com/reference/cli/docker/buildx/imagetools/create/
docker buildx imagetools create -t "${IMAGE}:${TAG}" ${IMAGES}
docker buildx imagetools inspect "${IMAGE}:${TAG}"
