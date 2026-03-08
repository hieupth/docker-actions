# docker-multiarch-merge

Download digest artifacts and create a multi-arch manifest tag. Use after `docker-multiarch-build` jobs complete.

## Key Terms

| Term | What It Means |
|------|---------------|
| **Digest** | A unique fingerprint of an image, like `sha256:abc123...`. Each platform build gets its own digest. |
| **Manifest** | A list that maps a tag (like `v1.0.0`) to specific digests for each platform. Created by merging digests. |
| **Artifact** | A file passed between GitHub Actions jobs. Digests are uploaded as artifacts during the build phase. |

## Features

- Download all platform digests
- Create and push multi-arch manifest

## Usage

### Complete Multi-Arch Workflow

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform: [linux/amd64, linux/arm64]
    steps:
      - uses: hieupth/gh-docker-actions/docker-multiarch-build@main
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app
          tag: v1.0.0
          platform: ${{ matrix.platform }}

  merge:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: hieupth/gh-docker-actions/docker-multiarch-merge@main
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app
          tag: v1.0.0
```

### Multiple Tags

```yaml
jobs:
  build:
    strategy:
      matrix:
        platform: [linux/amd64, linux/arm64]
        tag: [v1.0.0, latest]
    steps:
      - uses: hieupth/gh-docker-actions/docker-multiarch-build@main
        with:
          image: docker.io/user/app
          tag: ${{ matrix.tag }}
          platform: ${{ matrix.platform }}
          # ...

  merge:
    needs: build
    strategy:
      matrix:
        tag: [v1.0.0, latest]
    steps:
      - uses: hieupth/gh-docker-actions/docker-multiarch-merge@main
        with:
          image: docker.io/user/app
          tag: ${{ matrix.tag }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | no | `docker.io` | Registry host |
| `username` | yes | - | Registry username |
| `password` | yes | - | Registry password/token |
| `image` | yes | - | Image ref **WITHOUT tag** (e.g., `docker.io/user/app`) |
| `tag` | yes | - | Single tag to publish |
| `artifact_prefix` | no | `digests` | Prefix for artifact name (must match build) |
| `digests_path` | no | `/tmp/digests` | Path to download digests |
| `checkout` | no | `true` | Checkout repository |

## What It Does

1. Prepare Docker environment (uses [docker-prepare](docker-prepare.md)):
   - Setup Docker Buildx
   - Login to registry
   - Checkout repository
2. Download digest artifacts (pattern: `{artifact_prefix}-{tag}-*`)
3. Create multi-arch manifest using `docker buildx imagetools create`
4. Verify manifest with `docker buildx imagetools inspect`

## How Manifest Merge Works

```bash
# Downloaded digests:
# /tmp/digests/v1.0.0-linux-amd64.digest  → sha256:abc123...
# /tmp/digests/v1.0.0-linux-arm64.digest  → sha256:def456...

# Create multi-arch manifest:
docker buildx imagetools create \
  -t docker.io/user/app:v1.0.0 \
  docker.io/user/app@sha256:abc123... \
  docker.io/user/app@sha256:def456...

# Result: docker.io/user/app:v1.0.0 points to both platforms
```
