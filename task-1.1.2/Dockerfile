FROM ubuntu:20.04

LABEL org.opencontainers.image.title="Ruby 2.7.2" \
    org.opencontainers.image.authors="Andrey Leshkevich <magicgts@gmail.com>" \
    org.opencontainers.image.description="Ruby 2.7.2" \
    org.opencontainers.image.version="1.0"

RUN set -eux && \
    apt update &&\
    INSTALL_PKGS="git \
    curl \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    autoconf \
    bison \
    build-essential \
    libyaml-dev \
    libreadline-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm-dev" &&\
    apt install -y ${INSTALL_PKGS} &&\
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash &&\
    ~/.rbenv/bin/rbenv install 2.7.2 &&\
    ~/.rbenv/bin/rbenv global 2.7.2 &&\
    ln -s '/root/.rbenv/versions/2.7.2/bin/ruby' /usr/sbin/ruby &&\
    rm -rf /var/lib/apt/lists/*