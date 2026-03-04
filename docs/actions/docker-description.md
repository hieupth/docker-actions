# docker-description

Update DockerHub repository description from a file. Skips if file not found.

## Features

- Auto-detect description file
- Skip if file not found (no error)
- Auto-checkout if file not in workspace

## Usage

### Basic Usage

```yaml
- uses: hieupth/gh-docker-actions/docker-description@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    repository: docker.io/user/app
```

### Custom Description File

```yaml
- uses: hieupth/gh-docker-actions/docker-description@main
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    repository: user/app
    description_file: docs/README.md
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `username` | yes | - | DockerHub username |
| `password` | yes | - | DockerHub password/token |
| `repository` | yes | - | DockerHub repository (e.g., docker.io/user/app or user/app) |
| `description_file` | no | `README.md` | Path to description file. Skips if not found. |

## Behavior

1. Check if description file exists in workspace
2. If not found, checkout repository
3. If still not found, skip (no error)
4. If found, update DockerHub description
