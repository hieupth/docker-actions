# Github Docker Actions

A small collection of reusable GitHub Actions related to Docker workflows.

## Actions

| Action | Description |
|--------|-------------|
| [`docker-dind`](#docker-dind) | Run commands inside Docker with Docker-in-Docker |
| [`docker-build-push`](#docker-build-push) | Build and push images (single or multi-platform) |
| [`docker-multiarch-build`](#docker-multiarch-build) | Build single-platform, push by digest |
| [`docker-multiarch-merge`](#docker-multiarch-merge) | Merge multi-arch manifest |

---

## docker-dind

Run commands inside a Docker container with Docker-in-Docker capability and TTY support.

### Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `image` | **yes** | - | Docker image to run |
| `run` | no | - | Command to run inside container |
| `shell` | no | `bash` | Shell to use |
| `options` | no | - | Additional docker run options |
| `registry` | no | - | Registry URL for login |
| `username` | no | - | Registry username |
| `password` | no | - | Registry password/token |
| `docker_network` | no | auto | Docker network ID |
| `workdir` | no | - | Working directory inside container |
| `env` | no | - | Environment variables (newline-separated `KEY=VALUE`) |
| `cleanup` | no | `true` | Remove container after execution |
| `dry_run` | no | `false` | Print resolved inputs, skip docker run |
| `container_name` | no | auto | Custom container name for debugging |

### Example

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: hieupth/gh-docker-actions/docker-dind@v1
        with:
          image: golang:1.22
          run: |
            go test ./...
            docker build -t myapp .
```

---

## docker-build-push

Build and push Docker images (single or multi-platform) with automatic disk cleanup.

### Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `username` | **yes** | - | Registry username |
| `password` | **yes** | - | Registry password/token |
| `image` | **yes** | - | Full image reference with tag (e.g., `docker.io/user/app:latest`) |
| `registry` | no | `docker.io` | Registry host for login |
| `platforms` | no | `linux/amd64` | Platforms (comma-separated for multi-platform) |
| `context` | no | `.` | Build context path |
| `dockerfile` | no | `Dockerfile` | Dockerfile path |
| `build_args` | no | - | Build args (newline-separated `KEY=VALUE`) |
| `cache` | no | `false` | Enable GitHub Actions cache |
| `push` | no | `true` | Push image to registry |
| `free_disk_space` | no | `false` | Free disk space before build |
| `checkout` | no | `true` | Checkout repository before build |

### Example

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: hieupth/gh-docker-actions/docker-build-push@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app:latest
          platforms: linux/amd64,linux/arm64
          build_args: |
            VERSION=1.0.0
```

---

## docker-multiarch-build

Build a single-platform image, push by digest, upload digest as artifact. Use with `docker-multiarch-merge` for parallel multi-arch builds.

> **Recommended for large images**: Split build into parallel jobs to avoid timeout and disk space issues.

### Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `username` | **yes** | - | Registry username |
| `password` | **yes** | - | Registry password/token |
| `image` | **yes** | - | Image ref WITHOUT tag (e.g., `docker.io/user/app`) |
| `tag` | **yes** | - | Single tag (pass from matrix) |
| `platform` | **yes** | - | Single platform (e.g., `linux/amd64`) |
| `registry` | no | `docker.io` | Registry host for login |
| `context` | no | `.` | Build context path |
| `dockerfile` | no | `Dockerfile` | Dockerfile path |
| `build_args` | no | - | Build args (newline-separated `KEY=VALUE`) |
| `cache` | no | `false` | Enable GitHub Actions cache |
| `artifact_prefix` | no | `digests` | Prefix for artifact name |
| `retention_days` | no | `1` | Artifact retention days |
| `free_disk_space` | no | `true` | Free disk space before build |
| `checkout` | no | `true` | Checkout repository before build |

### Example

```yaml
jobs:
  build:
    strategy:
      matrix:
        platform: [linux/amd64, linux/arm64]
    runs-on: ubuntu-latest
    steps:
      - uses: hieupth/gh-docker-actions/docker-multiarch-build@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app
          tag: latest
          platform: ${{ matrix.platform }}
```

---

## docker-multiarch-merge

Download digest artifacts and create a multi-arch manifest tag. Use after `docker-multiarch-build` jobs complete.

> **Recommended for large images**: Merges digests from parallel builds into a single multi-arch manifest.

### Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `username` | **yes** | - | Registry username |
| `password` | **yes** | - | Registry password/token |
| `image` | **yes** | - | Image ref WITHOUT tag (e.g., `docker.io/user/app`) |
| `tag` | **yes** | - | Single tag to publish |
| `registry` | no | `docker.io` | Registry host for login |
| `artifact_prefix` | no | `digests` | Prefix for artifact name (must match build) |
| `digests_path` | no | `/tmp/digests` | Path to download digests |
| `checkout` | no | `true` | Checkout repository |

### Example

```yaml
jobs:
  build:
    # ... docker-multiarch-build jobs ...

  merge:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: hieupth/gh-docker-actions/docker-multiarch-merge@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          image: docker.io/user/app
          tag: latest
```

---

## License

[Apache License 2.0](LICENSE).

Copyright &copy; 2025 [Hieu Pham](https://github.com/hieupth). All rights reserved.
