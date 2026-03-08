# docker-prepare

Prepare Docker build environment with optional disk cleanup, QEMU, Buildx, login, and checkout.

!!! tip "Internal Action"
    This is an internal action used by other actions. You typically don't use it directly.

## Features

- Free disk space (optional)
- Setup QEMU for cross-platform builds (optional)
- Setup Docker Buildx
- Docker registry login
- Checkout repository (optional)

## Usage

### Full Setup (Default)

```yaml
- uses: hieupth/gh-docker-actions/docker-prepare@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

### Minimal Setup (No disk cleanup, No QEMU)

```yaml
- uses: hieupth/gh-docker-actions/docker-prepare@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    free_disk_space: false
    setup_qemu: false
```

### Without Checkout

```yaml
- uses: hieupth/gh-docker-actions/docker-prepare@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    checkout: false
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | no | `docker.io` | Registry host for login |
| `username` | yes | - | Registry username |
| `password` | yes | - | Registry password/token |
| `free_disk_space` | no | `true` | Free disk space before build |
| `setup_qemu` | no | `true` | Setup QEMU for cross-platform builds |
| `checkout` | no | `true` | Checkout repository |

## What It Does

1. **Free disk space** (if enabled) - Removes unused tools to make room for large builds
2. **Setup QEMU** (if enabled) - Enables cross-platform builds (ARM on AMD, etc.)
3. **Setup Buildx** - Docker's advanced build tool
4. **Docker login** - Authenticate with registry
5. **Checkout** (if enabled) - Clone repository
