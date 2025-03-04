FROM debian:bullseye-slim
ENV DEBIAN_FRONTEND noninteractive

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
    libncurses5-dev \
    libsdl1.2-dev \
    libsdl-image1.2-dev \
    libsdl-ttf2.0-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-ttf-dev \
    locales \
    make \
    rsync \
    scons \
    tree \
    unzip \
    wget \
    libsamplerate-dev \
    libsqlite3-dev \
    libjansson-dev \
    libfuzzy-dev \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/workspace
WORKDIR /root

COPY support .
RUN ./setup-toolchain.sh
RUN cat setup-env.sh >> .bashrc

# Upgrade pip and install additional Python packages
RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install numpy scipy scikit-learn transformers fuzzywuzzy[speedup] lxml pyinstaller

VOLUME /root/workspace
WORKDIR /root/workspace

CMD ["/bin/bash"]
