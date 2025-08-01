FROM debian:buster-slim
ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo "deb [trusted=yes] http://archive.debian.org/debian buster main non-free contrib" > /etc/apt/sources.list
RUN echo "deb-src [trusted=yes] http://archive.debian.org/debian buster main non-free contrib" >> /etc/apt/sources.list
RUN echo "deb [trusted=yes] http://archive.debian.org/debian-security buster/updates main non-free contrib" >> /etc/apt/sources.list

RUN apt-get -y update && apt-get -y install \
    bc \
    build-essential \
    bzip2 \
    bzr \
    cmake \
    cmake-curses-gui \
    cpio \
    git \
    libncurses5-dev \
    libsamplerate0-dev \
    #libzip-dev \
# 5.2 or newer for lzma/xz in libzip
    liblzma-dev \ 
# zstd support for libzip
    libzstd-dev \
# bz2 support for libzip
    libbz2-dev \
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

# stuff
COPY support .

RUN ./setup-toolchain.sh

# build newer libzip from source
RUN mkdir -p /root/builds
RUN ./build-libzip.sh > /root/builds/libzip.log

# build autotools (for bluez)
RUN ./build-autotools.sh > /root/builds/autotools.log
RUN ./build-bluez.sh > /root/builds/bluez.log

RUN cat setup-env.sh >> .bashrc

#ENV LD_PREFIX=/usr/aarch64-linux-gnu \
#      PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig

VOLUME /root/workspace
WORKDIR /root/workspace

CMD ["/bin/bash"]
