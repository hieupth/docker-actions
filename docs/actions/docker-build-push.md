# docker-build-push

Build and push a Docker image (single or multi-platform) with automatic disk cleanup.

!!! tip "Best For"
    Small to medium images (< 2 GB). For large images (5+ GB), use [docker-multiarch-build](docker-multiarch-build.md) + [docker-multiarch-merge](docker-multiarch-merge.md).

## When to Use This Action

| Scenario | Use This? | Better Alternative |
|----------|-----------|-------------------|
| Single platform, small image | ✅ Yes | - |
| Multi-platform, small image | ✅ Yes | - |
| Large image (5+ GB) | ⚠️ Slow | `docker-multiarch-build` + `docker-multiarch-merge` |
| Need parallel builds | ❌ No | `docker-multiarch-build` + `docker-multiarch-merge` |
| Need fault isolation per platform | ❌ No | `docker-multiarch-build` + `docker-multiarch-merge` |

## Features

- Single or multi-platform builds
- Automatic disk space cleanup
- GitHub Actions cache support
- Optional DockerHub description update

## Usage

### Single Platform

```yaml
- uses: hieupth/gh-docker-actions/docker-build-push@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    image: docker.io/user/app:latest
    platforms: linux/amd64
```

### Multi-Platform

```yaml
- uses: hieupth/gh-docker-actions/docker-build-push@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    image: docker.io/user/app:v1.0.0
    platforms: linux/amd64,linux/arm64
    context: .
    dockerfile: Dockerfile
    build_args: |
      VERSION=1.0.0
      ENV=production
```

### Build Only (No Push)

```yaml
- uses: hieupth/gh-docker-actions/docker-build-push@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    image: docker.io/user/app:test
    push: false
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | no | `docker.io` | Registry host for login |
| `username` | yes | - | Registry username |
| `password` | yes | - | Registry password/token |
| `image` | yes | - | Full image reference **with tag** (e.g., `docker.io/user/app:latest`) |
| `platforms` | no | `linux/amd64` | Platform(s) to build (comma-separated) |
| `context` | no | `.` | Build context path |
| `dockerfile` | no | `Dockerfile` | Dockerfile path |
| `build_args` | no | - | Build args (newline-separated KEY=VALUE) |
| `cache` | no | `true` | Enable build cache |
| `push` | no | `true` | Push image to registry |
| `description_file` | no | `README.md` | Path to description file for DockerHub |

## What It Does

1. Free disk space (remove unused tools)
2. Setup QEMU for cross-platform builds
3. Setup Docker Buildx
4. Login to registry
5. Build and push image
6. Update DockerHub description (if file exists)
