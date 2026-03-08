# Docker Actions

A collection of reusable GitHub Actions for Docker workflows.

**📚 [Full Documentation](https://hieupth.github.io/gh-docker-actions/)**

## Actions

| Action | Description |
|--------|-------------|
| [docker-dind](https://hieupth.github.io/gh-docker-actions/actions/docker-dind/) | Run commands inside Docker with Docker-in-Docker |
| [docker-build-push](https://hieupth.github.io/gh-docker-actions/actions/docker-build-push/) | Build and push images (single or multi-platform) |
| [docker-multiarch-build](https://hieupth.github.io/gh-docker-actions/actions/docker-multiarch-build/) | Build single-platform, push by digest |
| [docker-multiarch-merge](https://hieupth.github.io/gh-docker-actions/actions/docker-multiarch-merge/) | Merge multi-arch manifest |

## Quick Start

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

## License

[GNU AGPL v3.0](LICENSE).

Copyright &copy; 2025 [Hieu Pham](https://github.com/hieupth). All rights reserved.
