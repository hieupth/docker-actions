# CLAUDE.md

Reusable GitHub Actions for Docker CI/CD workflows.

## Actions Overview

| Action | Purpose | Use Case |
|--------|---------|----------|
| `docker-dind` | Run commands in Docker container with DinD support | Execute builds/tests inside containers |
| `docker-build-push` | Build + push image in one step | Small images (<2GB), simple workflows |
| `docker-multiarch-build` | Build single-platform, push by digest | Large images, matrix strategy |
| `docker-multiarch-merge` | Merge digests into multi-arch manifest | Final step of parallel multi-arch builds |
| `docker-prepare` | Setup Docker env (internal) | Used by other actions |

## Build Patterns

### Simple (Single Job)
```yaml
uses: hieupth/gh-docker-actions/docker-build-push@main
with:
  image: docker.io/user/app:latest
  platforms: linux/amd64,linux/arm64
```

### Parallel Multi-Arch (Matrix Strategy)
```yaml
# Job 1-N: Build each platform (matrix)
uses: hieupth/gh-docker-actions/docker-multiarch-build@main
with:
  image: docker.io/user/app
  tag: ${{ matrix.tag }}
  platform: ${{ matrix.platform }}

# Job N+1: Merge manifests
uses: hieupth/gh-docker-actions/docker-multiarch-merge@main
with:
  image: docker.io/user/app
  tag: latest
```

## Conventions

- **All actions**: Composite (`using: composite`)
- **Scripts**: Use `set -euo pipefail` for strict mode
- **Registry auth**: Always via `docker/login-action@v3`
- **Multi-platform**: Uses `docker/setup-qemu-action@v3` + `setup-buildx-action@v3`
- **Disk cleanup**: `jlumbroso/free-disk-space@v1.3.1` before builds
- **Backward compatible**: `docker-dind` compatible with `hieupth/inside-container-action`

## File Structure

```
docker-{name}/
├── action.yml       # Action definition
└── {script}.sh      # Helper scripts (if needed)
```

## Required Inputs

All build-related actions require:
- `username`: Registry username
- `password`: Registry password/token
- `image`: Image reference (with or without tag depending on action)

## Documentation

- MkDocs with Material theme
- Docs in `docs/` directory
- Deployed via `.github/workflows/docs.yml`
