# Docker Actions

Collection of reusable GitHub Actions for Docker workflows.

## Available Actions

| Action | Purpose | Best For |
|--------|---------|----------|
| [docker-dind](actions/docker-dind.md) | Run commands inside Docker with DinD | Container-based CI/CD |
| [docker-build-push](actions/docker-build-push.md) | Build and push in one step | **Small images**, simple workflows |
| [docker-multiarch-build](actions/docker-multiarch-build.md) | Build single-platform by digest | **Large images**, parallel builds |
| [docker-multiarch-merge](actions/docker-multiarch-merge.md) | Merge digests into manifest | Multi-platform final step |
| [docker-description](actions/docker-description.md) | Update DockerHub description | Post-push automation |

## When to Use Which?

| Use Case | Recommended Action |
|----------|-------------------|
| Small image (< 2 GB), single platform | `docker-build-push` |
| Small image (< 2 GB), multi-platform | `docker-build-push` with `platforms` |
| Large image (5+ GB), multi-platform | `docker-multiarch-build` + `docker-multiarch-merge` |
| Need fault isolation per platform | `docker-multiarch-build` + `docker-multiarch-merge` |
| Run commands inside container | `docker-dind` |

## Quick Start

### Simple Build

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: hieupth/gh-docker-actions/docker-build-push@main
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app:latest
```

### Multi-Platform Build

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: hieupth/gh-docker-actions/docker-build-push@main
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app:latest
          platforms: linux/amd64,linux/arm64
```

### Large Images (Parallel Build)

```yaml
jobs:
  build:
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
    needs: build
    steps:
      - uses: hieupth/gh-docker-actions/docker-multiarch-merge@main
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app
          tag: v1.0.0
```

## Key Concepts

| Term | Simple Explanation |
|------|-------------------|
| **Digest** | A unique fingerprint of an image (like a SHA hash). Example: `sha256:abc123...` |
| **Manifest** | A list that points to different platform versions of the same image |
| **QEMU** | Software that lets you build ARM images on AMD machines (and vice versa) |
| **Buildx** | Docker's advanced build tool with multi-platform support |
| **Docker-in-Docker** | Running Docker commands inside a Docker container |

## License

[GNU AGPL v3.0](https://github.com/hieupth/gh-docker-actions/blob/main/LICENSE)
