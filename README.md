# hieupth/docker-actions

A collection of reusable GitHub Actions for building and merging multi-platform Docker images using the **push-by-digest** pattern recommended by Docker.

## Overview

This repository provides two composite actions that work together:

| Action | Purpose |
|--------|---------|
| `docker-multiarch-build` | Build and push a **single-platform** image by digest, then upload the digest as an artifact |
| `docker-multiarch-merge` | Download digest artifacts and create a **multi-arch manifest list** |

### Why This Pattern?

Unlike traditional multi-platform builds that use `docker buildx build` with multiple platforms in a single command, this approach:

1. **Parallel execution**: Each platform builds independently in separate matrix jobs
2. **Fault isolation**: One platform's failure doesn't affect others
3. **Efficient uploads**: Only digests (~bytes) are passed between jobs, not multi-GB images
4. **Better CI/CD performance**: Total time = max(single platform time), not sum(all platforms)

---

## Actions

### 1. `docker-multiarch-build`

Builds and pushes a single-platform image using **push-by-digest**, then uploads the resulting digest as a workflow artifact.

**Typical usage**: Run this action in a matrix over platforms (e.g., `linux/amd64`, `linux/arm64`). A later job merges those digests into one multi-arch tag.

#### Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | No | `docker.io` | Registry host for login |
| `username` | Yes | - | Registry username |
| `password` | Yes | - | Registry password/token |
| `image` | Yes | - | Image reference **without tag** (e.g., `docker.io/user/app`) |
| `tag` | Yes | - | Tag name used to name digest artifacts (caller can pass `matrix.tag`) |
| `platform` | Yes | - | Single platform for this job (e.g., `linux/amd64`) |
| `context` | No | `.` | Build context path |
| `dockerfile` | No | `dockerfile` | Dockerfile path |
| `build_args` | No | `""` | Build args as newline-separated `KEY=VALUE` |
| `artifact_prefix` | No | `digests` | Artifact name prefix |
| `retention_days` | No | `1` | Artifact retention days |

#### Features

- **Automatic disk cleanup**: Frees disk space before build using `jlumbroso/free-disk-space@v1.3.1`
- **QEMU emulation**: Sets up cross-platform building capability
- **Push-by-digest**: Follows Docker's recommended pattern for multi-platform builds

---

### 2. `docker-multiarch-merge`

Downloads digest artifacts created by `docker-multiarch-build`, then creates and pushes a **multi-arch manifest list** for `image:tag`.

#### Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | No | `docker.io` | Registry host for login |
| `username` | Yes | - | Registry username |
| `password` | Yes | - | Registry password/token |
| `image` | Yes | - | Image reference **without tag** (e.g., `docker.io/user/app`) |
| `tag` | Yes | - | Tag to publish (e.g., `25.11`) |
| `artifact_prefix` | No | `digests` | Artifact name prefix (must match build action) |
| `digests_path` | No | `/tmp/digests` | Where digests are downloaded |

#### Features

- **Artifact pattern matching**: Uses GitHub Actions v4's `pattern` + `merge-multiple` to download all platform digests at once
- **Manifest creation**: Uses `docker buildx imagetools create` to merge digests into a multi-arch tag
- **Verification**: Runs `docker buildx imagetools inspect` to verify the manifest

---

## Example Workflow

```yaml
name: Build Multi-Platform Docker Images

on:
  workflow_dispatch:
  push:
    branches: ["main"]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        platform: ["linux/amd64", "linux/arm64"]
        tag: ["25.01"]

    steps:
      - uses: actions/checkout@v4

      # Optional: compute build args dynamically
      - name: Compute BASE_IMAGE
        id: base
        shell: bash
        run: |
          set -euo pipefail
          echo "base_image=ubuntu:22.04" >> "$GITHUB_OUTPUT"

      - name: Build per-platform digest
        uses: hieupth/docker-actions/docker-multiarch-build@v1
        with:
          registry: docker.io
          username: ${{ vars.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          image: docker.io/${{ vars.DOCKERHUB_USERNAME }}/myapp
          tag: ${{ matrix.tag }}
          platform: ${{ matrix.platform }}
          dockerfile: Dockerfile
          context: .
          build_args: |
            BASE_IMAGE=${{ steps.base.outputs.base_image }}

  merge:
    runs-on: ubuntu-latest
    needs: build
    strategy:
      matrix:
        tag: ["25.01"]

    steps:
      - name: Merge digests into multi-arch tag
        uses: hieupth/docker-actions/docker-multiarch-merge@v1
        with:
          registry: docker.io
          username: ${{ vars.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          image: docker.io/${{ vars.DOCKERHUB_USERNAME }}/myapp
          tag: ${{ matrix.tag }}
          artifact_prefix: digests
```

---

## Benefits for Large Images (e.g., Triton Inference Server)

Building large Docker images like **NVIDIA Triton Inference Server** (often 5-10+ GB per platform) presents unique challenges:

### Problem with Traditional Approach

```
Single Job Multi-Platform Build:
┌─────────────────────────────────────────┐
│  docker buildx build                    │
│  ├── linux/amd64  → 8 GB, ~45 minutes   │
│  ├── linux/arm64  → 8 GB, ~50 minutes   │
│  └── Total time: ~95 minutes (serial)   │
│  └── Memory: ~16 GB for QEMU emulation  │
└─────────────────────────────────────────┘
```

**Issues**:
- Sequential build: platforms build one after another
- High memory usage: QEMU emulation for all platforms simultaneously
- Single point of failure: one crash = restart everything
- Timeout risk: large builds may exceed GitHub's 6-hour timeout

### Solution with These Actions

```
Parallel Matrix Build:
┌─────────────────────┐  ┌─────────────────────┐
│  Job: amd64         │  │  Job: arm64         │
│  └── 8 GB, 45 min   │  │  └── 8 GB, 50 min   │
└─────────────────────┘  └─────────────────────┘
         │                        │
         └────────┬───────────────┘
                  ▼
    ┌─────────────────────────┐
    │  Merge Job: < 1 min     │
    │  (digests are ~bytes)   │
    └─────────────────────────┘

    Total time: ~50 minutes (parallel)
```

**Benefits**:

| Aspect | Traditional | This Approach |
|--------|-------------|---------------|
| **Build time** | Sum of all platforms | Max of any single platform |
| **Memory per job** | High (all platforms) | Low (single platform) |
| **Fault tolerance** | All-or-nothing | Isolated per platform |
| **Rebuild cost** | Full rebuild | Only failed platform |
| **Artifact transfer** | Multi-GB images | Bytes (digests only) |
| **Scalability** | Limited by RAM/timeout | Add more platforms easily |

### Practical Example: Triton Inference Server

For a Triton image with `linux/amd64`, `linux/arm64`, `linux/ppc64le`:

| Platform | Image Size | Build Time |
|----------|-----------|------------|
| linux/amd64 | ~8 GB | ~40 min |
| linux/arm64 | ~8 GB | ~45 min |
| linux/ppc64le | ~9 GB | ~50 min |

**Traditional approach**: ~135 minutes total, high risk of timeout

**This approach**: ~50 minutes total (all platforms build in parallel)

---

## How It Works

### Step 1: Build (Per Platform)

```bash
# Each matrix job builds ONE platform
docker buildx build \
  --platform linux/amd64 \
  --push \
  --output type=image,name=docker.io/user/app,push-by-digest=true,name-canonical=true \
  .

# Result: digest uploaded as artifact
# digest file content: sha256:abc123...
```

### Step 2: Merge

```bash
# Download all digest artifacts
# /tmp/digests/25.01-linux-amd64.digest  → sha256:abc123...
# /tmp/digests/25.01-linux-arm64.digest  → sha256:def456...

# Create multi-arch manifest
docker buildx imagetools create \
  -t docker.io/user/app:25.01 \
  docker.io/user/app@sha256:abc123... \
  docker.io/user/app@sha256:def456...

# Result: docker.io/user/app:25.01 now points to both platforms
```

---

## Notes

- `docker-multiarch-build` must upload unique artifact names per platform
- `docker-multiarch-merge` downloads them using an artifact name pattern
- The `artifact_prefix` must match between both actions

## References

- [Docker Multi-Platform Images](https://docs.docker.com/build/ci/github-actions/multi-platform/)
- [GitHub Actions Artifacts v4](https://github.blog/changelog/2023-12-14-github-actions-artifacts-v4-is-now-generally-available/)
- [Docker Buildx Imagetools](https://docs.docker.com/reference/cli/docker/buildx/imagetools/create/)

## LICENSE

[Apache License 2.0](LICENSE)

Copyright &copy; 2025 [Hieu Pham](https://github.com/hieupth). All rights reserved.
