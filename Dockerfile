FROM debian:buster-slim
ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && apt-get -y install \
    bc \
    build-essential \
    bzip2 \
    bzr \
    cmake \
    cmake-curses-gui \
    cpio \
    git \
    locales \
    make \
    rsync \
    scons \
    tree \
    unzip \
    wget \
    python3 \
    python3-pip \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
  && rm -rf /var/lib/apt/lists/*

# Dependencies
RUN dpkg --add-architecture arm64
RUN apt-get -y update && apt-get -y install \
    libncurses5-dev:arm64 \
    libsdl1.2-dev:arm64 \
    libsdl-image1.2-dev:arm64 \
    libsdl-ttf2.0-dev:arm64 \
    libsdl2-dev:arm64 \
    libsdl2-image-dev:arm64 \
    libsdl2-ttf-dev:arm64 \
    libsamplerate0-dev:arm64 \
    libsqlite3-dev:arm64 \
    libjansson-dev:arm64 \
    libfuzzy-dev:arm64 \
    libbluetooth-dev:arm64 \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/workspace
WORKDIR /root

COPY support .
RUN ./setup-toolchain.sh
RUN cat setup-env.sh >> .bashrc

ENV LD_PREFIX=/usr/aarch64-linux-gnu \
    PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig



# Upgrade pip and install additional Python packages
# RUN python3 -m pip install --upgrade pip \
#     && python3 -m pip install numpy scipy scikit-learn transformers fuzzywuzzy[speedup] lxml pyinstaller

VOLUME /root/workspace
WORKDIR /root/workspace

CMD ["/bin/bash"]
