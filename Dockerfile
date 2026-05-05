FROM rocker/r-ver:4.5
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
                        CRAN = Sys.getenv('RSPM')))" > /root/.Rprofile
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
ENV PATH="/root/.local/bin:$PATH"
ENV PRE_COMMIT_HOME=/opt/pre-commit-cache
RUN curl https://raw.githubusercontent.com/pik-piam/lucode2/refs/heads/master/inst/extdata/pre-commit-config.yaml > .pre-commit-config.yaml && \
    pipx ensurepath && \
    pipx install pre-commit && \
    git init . && \
    pre-commit run --show-diff-on-failure --color=always --all-files && \
    rm .pre-commit-config.yaml


#
# Wrap up
#
WORKDIR /
