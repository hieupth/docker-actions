# docker-dind

Run commands inside a Docker container with TTY support and Docker-in-Docker capability.

!!! tip "What is Docker-in-Docker?"
    **Docker-in-Docker (DinD)** lets you run Docker commands inside a Docker container. This is useful when your CI job needs to build, run, or manage other containers.

    Think of it like "nested containers" - a container that can control the Docker daemon.

## Features

- TTY support for interactive commands
- Docker-in-Docker capability (mount docker.sock)
- Multi-platform support
- Auto cleanup containers
- Custom working directory
- Environment variables injection

## What It Does

1. **Docker login** (optional, only if username/password provided)
2. **Pulls the specified image** from a registry
3. **Creates a container** with custom options (volumes, environment, network)
4. **Runs your command** inside the container with TTY support
5. **Cleans up** the container after execution (if `cleanup: true`)

## Usage

### Basic Usage

```yaml
- uses: hieupth/gh-docker-actions/docker-dind@main
  with:
    image: hieupth/mamba:cuda
    run: |
      echo "Hello from container"
      nvidia-smi
```

### With Registry Login

```yaml
- uses: hieupth/gh-docker-actions/docker-dind@main
  with:
    registry: docker.io
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    image: hieupth/mamba:cuda
    run: bash /build.sh
    options: |
      -v ./build.sh:/build.sh
      -e VERSION=${{ matrix.version }}
```

### With Custom Environment

```yaml
- uses: hieupth/gh-docker-actions/docker-dind@main
  with:
    image: hieupth/mamba:cuda
    workdir: /workspace
    env: |
      CUDA_VERSION=12.0
      BUILD_TYPE=release
    run: |
      cd /workspace
      make build
    cleanup: true
    container_name: my-build-container
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `image` | yes | - | Docker image to run |
| `run` | no | - | Command to run inside container |
| `shell` | no | `bash` | Shell to use |
| `options` | no | - | Additional docker run options |
| `registry` | no | - | Docker registry URL |
| `username` | no | - | Registry username |
| `password` | no | - | Registry password/token |
| `docker_network` | no | `job.container.network` | Docker network ID |
| `workdir` | no | - | Working directory inside container |
| `env` | no | - | Environment variables (newline-separated KEY=VALUE) |
| `cleanup` | no | `true` | Remove container after execution |
| `dry_run` | no | `false` | Print resolved inputs and skip docker run |
| `container_name` | no | auto-generated | Custom container name |

## Migration from inside-container-action

This action is fully backward compatible with `hieupth/inside-container-action`. Simply change:

```yaml
# Before
- uses: hieupth/inside-container-action@main

# After
- uses: hieupth/gh-docker-actions/docker-dind@main
```

All existing inputs work exactly the same way.
