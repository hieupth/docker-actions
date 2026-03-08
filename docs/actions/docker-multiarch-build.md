# docker-multiarch-build

Build a single-platform image, push by digest, and upload digest as an artifact. Use together with `docker-multiarch-merge` for multi-arch builds.

!!! tip "Best For"
    Large images (5+ GB) with multi-platform support. Enables parallel builds with fault isolation.

## Key Terms

| Term | What It Means |
|------|---------------|
| **Digest** | A unique fingerprint of an image, like `sha256:abc123...`. Each platform build gets its own digest. |
| **Manifest** | A list that maps a tag (like `v1.0.0`) to specific digests for each platform. |
| **QEMU** | Software that emulates different CPU architectures. Lets you build ARM images on AMD runners. |
| **Buildx** | Docker's modern build tool with multi-platform support and advanced caching. |

## Features

- Build single platform per job (parallel builds)
- Push by digest for later manifest merge
- Upload digest artifact
- Automatic disk space cleanup

## Usage

### Matrix Build

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
```

### With Build Args

```yaml
- uses: hieupth/gh-docker-actions/docker-multiarch-build@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    image: docker.io/user/app
    tag: v1.0.0
    platform: ${{ matrix.platform }}
    build_args: |
      VERSION=1.0.0
      ENV=production
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | no | `docker.io` | Registry host for login |
| `username` | yes | - | Registry username |
| `password` | yes | - | Registry password/token |
| `image` | yes | - | Image ref **WITHOUT tag** (e.g., `docker.io/user/app`) |
| `tag` | yes | - | Single tag to publish |
| `platform` | yes | - | Single platform (e.g., `linux/amd64`) |
| `context` | no | `.` | Build context path |
| `dockerfile` | no | `Dockerfile` | Dockerfile path |
| `build_args` | no | - | Build args (newline-separated KEY=VALUE) |
| `artifact_prefix` | no | `digests` | Prefix for artifact name |
| `retention_days` | no | `1` | Artifact retention days |
| `checkout` | no | `true` | Checkout repository before build |

## What It Does

1. Prepare Docker environment (uses [docker-prepare](docker-prepare.md)):
   - Free disk space
   - Setup QEMU for cross-platform builds
   - Setup Docker Buildx
   - Login to registry
   - Checkout repository
2. Build and push **by digest** (not by tag)
3. Upload digest as artifact

## Why Push-by-Digest?

```
Traditional Multi-Platform Build:
┌─────────────────────────────────────────┐
│  docker buildx build                    │
│  ├── linux/amd64  → 8 GB, ~45 minutes   │
│  ├── linux/arm64  → 8 GB, ~50 minutes   │
│  └── Total time: ~95 minutes (serial)   │
└─────────────────────────────────────────┘

Push-by-Digest (This Action):
┌─────────────────────┐  ┌─────────────────────┐
│  Job: amd64         │  │  Job: arm64         │
│  └── 8 GB, 45 min   │  │  └── 8 GB, 50 min   │
└─────────────────────┘  └─────────────────────┘
         │                        │
         └────────┬───────────────┘
                  ▼
    Total time: ~50 minutes (parallel)
```

## Next Step

After all platform builds complete, use [docker-multiarch-merge](docker-multiarch-merge.md) to create the multi-arch manifest.
