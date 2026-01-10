FROM docker.io/library/ubuntu:24.04

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
    wget -qO - $TOOLCHAIN_URL | tar -xJ -C ${TOOLCHAIN_DIR} --strip-components=2

ENV CROSS_TRIPLE=aarch64-nextui-linux-gnu
ENV CROSS_ROOT=${TOOLCHAIN_DIR}
ENV SYSROOT=${CROSS_ROOT}/${CROSS_TRIPLE}/libc

# Download and extract the SDK sysroot
ARG SDK_URL=https://github.com/trimui/toolchain_sdk_smartpro/releases/download/20231018/SDK_usr_tg5040_a133p.tgz
RUN mkdir -p ${SYSROOT} && wget -qO - ${SDK_URL} | tar -xzC ${SYSROOT}

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
ENV CMAKE_TOOLCHAIN_FILE=${CROSS_ROOT}/Toolchain.cmake
COPY toolchain-aarch64.cmake ${CMAKE_TOOLCHAIN_FILE}

#ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
ENV PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig

# for c
#ENV CFLAGS="--sysroot=${SYSROOT} -I\"$SYSROOT/libc/usr/include\""
#ENV CXXFLAGS="--sysroot=$SYSROOT -I\"$SYSROOT/include/c++/8.3.0\" -I\"$SYSROOT/include/c++/8.3.0/aarch64-nextui-linux-gnu\" -I\"$SYSROOT/libc/usr/include\""
#ENV LDFLAGS="--sysroot=${SYSROOT} -L\"$SYSROOT/lib\" -L\"$SYSROOT/libc/usr/lib\""

# stuff and extra libs
COPY support /root/support
RUN /root/support/build-libzip.sh
RUN /root/support/build-bluez.sh
RUN /root/support/build-libsamplerate.sh
RUN /root/support/build-lz4.sh

ENV UNION_PLATFORM=tg5040
# do we still need this?
ENV PREFIX_LOCAL=/opt/nextui

# just to make sure
RUN mkdir -p ${PREFIX_LOCAL}/include ${PREFIX_LOCAL}/lib

VOLUME /root/workspace
WORKDIR /root/workspace
