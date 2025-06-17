FROM debian:buster-slim
ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN dpkg --add-architecture arm64
RUN apt-get -y update && apt-get -y install \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    pkg-config \
    crossbuild-essential-arm64 \
    bc \
    build-essential \
    bzip2 \
    bzr \
    cmake \
    cmake-curses-gui \
    cpio \
    git \
    libncurses5-dev \
    libsamplerate0-dev:arm64 \
    # we need this one for cores to compile..
    libzip-dev:arm64 \
# 5.2 or newer for lzma/xz in libzip
    liblzma-dev:arm64 \ 
# zstd support for libzip
    libzstd-dev:arm64 \
# bz2 support for libzip
    libbz2-dev:arm64 \
# zlib for libzip
    zlib1g-dev \
  # deprecated, but also supplied by the SDK
#    libsdl1.2-dev \
#    libsdl-image1.2-dev \
#    libsdl-ttf2.0-dev \
# supplied by SDK
#    libsdl2-dev \
#    libsdl2-image-dev \
#    libsdl2-ttf-dev \
#    libsqlite3-dev \
#    libbluetooth-dev \
    # For libwpa_client.a
    #libwpa-client-dev \
    locales \
    make \
    rsync \
    scons \
    tree \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/*
  
RUN mkdir -p /root/workspace
WORKDIR /root

COPY support .


RUN ./setup-toolchain.sh
RUN cat setup-env.sh >> .bashrc

ENV LD_PREFIX=/usr/aarch64-linux-gnu \
    PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig \ 
    PKG_CONFIG_LIBDIR=/root/builds/libzip/build/lib:/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/opt/aarch64-linux-gnu/aarch64-linux-gnu/lib/pkgconfig


# build newer libzip from source
RUN ./build-libzip.sh

VOLUME /root/workspace
WORKDIR /root/workspace

CMD ["/bin/bash"]
