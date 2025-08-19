FROM ubuntu:24.04

# Install base build tools and dependencies
RUN apt-get update && apt-get install -y \
    make \
    #    build-essential \
    cmake \
    ninja-build \
    autotools-dev \
    autoconf \
    automake \
    autopoint \
    libtool \
    po4a \
    m4 \
    pkg-config \
    unzip \
    wget \
    git \
    python3 \
    ca-certificates \
    gettext \
    vim \
    && rm -rf /var/lib/apt/lists/*

COPY support /root/support

ENV TOOLCHAIN_DIR=/opt/aarch64-nextui-linux-gnu

# Download the appropriate cross toolchain based on host arch
RUN mkdir -p ${TOOLCHAIN_DIR} && \
    ARCH=$(uname -m) && \
    TOOLCHAIN_REPO=https://github.com/LoveRetro/gcc-arm-8.3-aarch64-tg5040 && \
    TOOLCHAIN_BUILD=v8.3.0-20250814-133302-c13dfc38 && \
    if [ "$ARCH" = "x86_64" ]; then \
        TOOLCHAIN_ARCHIVE=gcc-8.3.0-aarch64-nextui-linux-gnu-x86_64-host.tar.xz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        TOOLCHAIN_ARCHIVE=gcc-8.3.0-aarch64-nextui-linux-gnu-arm64-host.tar.xz; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    TOOLCHAIN_URL=${TOOLCHAIN_REPO}/releases/download/${TOOLCHAIN_BUILD}/${TOOLCHAIN_ARCHIVE}; \
    wget -q $TOOLCHAIN_URL -O /tmp/toolchain.tar.xz && \
    tar -xf /tmp/toolchain.tar.xz -C ${TOOLCHAIN_DIR} --strip-components=2 && \
    rm /tmp/toolchain.tar.xz

ENV CROSS_TRIPLE=aarch64-nextui-linux-gnu
ENV CROSS_ROOT=${TOOLCHAIN_DIR}
ENV SYSROOT=${CROSS_ROOT}/${CROSS_TRIPLE}/libc

# Download and extract the SDK sysroot
ENV SDK_TAR=SDK_usr_tg5040_a133p.tgz
ENV SDK_URL=https://github.com/trimui/toolchain_sdk_smartpro/releases/download/20231018/${SDK_TAR}

RUN mkdir -p ${SYSROOT} && \
wget -q ${SDK_URL} -O /tmp/${SDK_TAR} && \
tar -xzf /tmp/${SDK_TAR} -C ${SYSROOT} && \
rm /tmp/${SDK_TAR}

ENV AS=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-as \
    AR=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ar \
    CC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gcc \
    CPP=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-cpp \
    CXX=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-g++ \
    LD=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ld

# Linux kernel cross compilation variables
ENV PATH=${CROSS_ROOT}/bin:${PATH}
ENV CROSS_COMPILE=${CROSS_TRIPLE}-
ENV PREFIX=${SYSROOT}/usr
ENV ARCH=arm64

# qemu, anyone?
#ENV QEMU_LD_PREFIX="${CROSS_ROOT}/${CROSS_TRIPLE}/sysroot"
#ENV QEMU_SET_ENV="LD_LIBRARY_PATH=${CROSS_ROOT}/lib:${QEMU_LD_PREFIX}"

# CMake toolchain
COPY toolchain-aarch64.cmake ${CROSS_ROOT}/Toolchain.cmake
ENV CMAKE_TOOLCHAIN_FILE=${CROSS_ROOT}/Toolchain.cmake

#ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
ENV PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig

# for c
#ENV CFLAGS="--sysroot=${SYSROOT} -I\"$SYSROOT/libc/usr/include\""
#ENV CXXFLAGS="--sysroot=$SYSROOT -I\"$SYSROOT/include/c++/8.3.0\" -I\"$SYSROOT/include/c++/8.3.0/aarch64-nextui-linux-gnu\" -I\"$SYSROOT/libc/usr/include\""
#ENV LDFLAGS="--sysroot=${SYSROOT} -L\"$SYSROOT/lib\" -L\"$SYSROOT/libc/usr/lib\""

# stuff and extra libs
COPY support .
RUN ./build-libzip.sh
RUN ./build-bluez.sh
RUN ./build-libsamplerate.sh


ENV UNION_PLATFORM=tg5040
# do we still need this?
ENV PREFIX_LOCAL=/opt/nextui

# just to make sure
RUN mkdir -p ${PREFIX_LOCAL}/include
RUN mkdir -p ${PREFIX_LOCAL}/lib

VOLUME /root/workspace
WORKDIR /workspace

CMD ["/bin/bash"]
