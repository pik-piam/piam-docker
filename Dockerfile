FROM rocker/r-ubuntu:latest
WORKDIR /tmp/setup

#
# Prepare the OS
#
RUN echo "apt::install-recommends \"false\";" > /etc/apt/apt.conf.d/95-no-install-recommends
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
      ca-certificates curl wget jq git \
      pandoc \
      python3 pipx \
      libcurl4-openssl-dev libssl-dev libfontconfig1-dev \
      libfreetype6-dev libfribidi-dev libharfbuzz-dev libjpeg-dev \
      libpng-dev libtiff-dev libicu-dev libgit2-dev zlib1g-dev \
      rsync \
    && rm -rf /var/lib/apt/lists/*

RUN git config --system safe.directory "*"


#
# Pre-install R packages
#
ENV RSPM='https://packagemanager.posit.co/cran/__linux__/noble/latest'
ENV RENV_CONFIG_REPOS_OVERRIDE='https://packagemanager.posit.co/cran/__linux__/noble/latest'

RUN <<EOF 
echo "options(repos = c(pikpiam = 'https://pik-piam.r-universe.dev',
                        rse = 'https://rse.pik-potsdam.de/r/packages',
                        CRAN = Sys.getenv('RSPM')))" > ~/.Rprofile
EOF

RUN Rscript -e " \
  install.packages('pak'); \
  # Installing base dependencies \
  pak::pak(c('pkgdown', 'devtools', 'covr')); \
  # Installing major pik-piam packages \
  pak::pak(c('lucode2', 'madrat', 'magclass', 'mrremind', 'magpie4', 'remind2', 'mip', 'quitte'));\
  " \
  && rm -rf /var/lib/apt/lists/*


# 
# Set up pre-commit. 
# First install pre-commit itself, then the actual checks
# 
RUN <<EOF 
echo "exclude: '^tests/testthat/_snaps/.*$'
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: cef0300fd0fc4d2a87a85fa2093c6b283ea36f4b  # frozen: v5.0.0
    hooks:
    -   id: check-case-conflict
    -   id: check-json
    -   id: check-merge-conflict
    -   id: check-yaml
    -   id: fix-byte-order-marker
    -   id: check-added-large-files
        args: ['--maxkb=100']
    -   id: mixed-line-ending

-   repo: https://github.com/lorenzwalthert/precommit
    rev: 3b70240796cdccbe1474b0176560281aaded97e6  # frozen: v0.4.3.9003
    hooks:
    -   id: parsable-R
    -   id: deps-in-desc
        args: [--allow_private_imports]
    -   id: no-browser-statement
    -   id: no-debug-statement
    -   id: readme-rmd-rendered
    -   id: use-tidy-description" > .pre-commit-config.yaml
EOF

ENV PATH="/root/.local/bin:$PATH"
RUN pipx ensurepath && \
    pipx install pre-commit && \
    git init . && \
    pre-commit run --show-diff-on-failure --color=always --all-files && \
    rm .pre-commit-config.yaml


#
# Wrap up
#
WORKDIR /
