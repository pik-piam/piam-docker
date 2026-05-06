# PIAM Docker

Currently only contains the CI image.

## CI/CD Image

Docker image for CI/CD pipelines in the [pik-piam](https://github.com/pik-piam) R package ecosystem.

Published to: `ghcr.io/pik-piam/ci-image`

### Contents

Built on [`rocker/r-ver:4.5`](https://rocker-project.org/), the image bundles:

- **Common dependencies of piam packages** - Including OS packages
- **Common R tools** - `devtools`, `pkgdown`, `covr`
- **pre-commit** - installed via `pipx`, with the pik-piam pre-commit hook cache pre-populated so hooks run without network access at CI time


### Rebuild

The image is rebuilt automatically on:

- Every push to `main` that touches the `Dockerfile`
- Every Sunday (weekly scheduled build to pick up updated package versions)
- Manual trigger via `workflow_dispatch`

### Usage

```yaml
# Example GitHub Actions job
jobs:
  check:
    runs-on: ubuntu-latest
    container: ghcr.io/pik-piam/ci-image:latest
    steps:
      - uses: actions/checkout@v4
      - run: Rscript -e "devtools::check()"
```

### Tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent build from `main` |
| `<git-sha>` | Pinned build for reproducibility |
