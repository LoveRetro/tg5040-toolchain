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

# lzma/xz
RUN git clone https://github.com/tukaani-project/xz.git /tmp/xz && \
    cd /tmp/xz && \
    ./autogen.sh && \
    ./configure \
       --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT/usr \
        --disable-static \
        --enable-shared \
        --with-sysroot=$SYSROOT && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/xz

# zstd
RUN git clone --depth=1 https://github.com/facebook/zstd.git /tmp/zstd && \
    cd /tmp/zstd/build/cmake && \
    cmake . \
        -DCMAKE_INSTALL_PREFIX=$SYSROOT/usr \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/zstd

# bz2
RUN wget -q https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz -O /tmp/bzip2.tar.gz && \
    cd /tmp && tar -xzf bzip2.tar.gz && cd bzip2-1.0.8 && \
    make -j$(nproc) && \
    make PREFIX=$SYSROOT/usr install && \
    rm -rf /tmp/bzip2*

# libzip
RUN git clone https://github.com/nih-at/libzip.git /tmp/libzip && \
    mkdir /tmp/libzip/build && cd /tmp/libzip/build && \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=$SYSROOT/usr \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/libzip

# bluez
# 5.80 contains a reference to rl_clear_visible_line, which would require a newer ncurses/tinfo
# 5.79 changes to obexd/client/bip-common cause some warnings/errors
# 5.78 works
RUN git clone --depth 1 --branch 5.78 https://github.com/bluez/bluez.git /tmp/bluez && \
    cd /tmp/bluez && \
    sed -i 's/-lreadline\b/-lreadline -L\/usr\/lib -lncurses/g' Makefile.tools && \
    ./bootstrap && \
    ./configure \
        --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT/usr \
        --disable-systemd \
        --disable-udev \
        --disable-cups \
        --disable-obex \
        --disable-manpages \
        --with-sysroot=$SYSROOT && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/bluez

# libsbc
# not sure how thats possible, but the libsbc that trimui is shipping (and claims to be 1.2.1)
# does not export a sbc_reinit_a2dp - which is the whole point of 1.2.x.
RUN git clone --depth 1 --branch 2.1 https://git.kernel.org/pub/scm/bluetooth/sbc.git /tmp/sbc && \
    cd /tmp/sbc && \
    autoreconf --install && \
    mkdir build && cd build && \
    ../configure  \
        --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT/usr \
        --with-sysroot=$SYSROOT && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/sbc

# bluez-alsa
# 4.1.0 this is the latest we can build without replacing glib 2.50.1 and sbc 1.2.1
# 4.1.1 misses gdbus-codegen
RUN git clone --depth 1 --branch v4.1.0 https://github.com/arkq/bluez-alsa.git /tmp/bluez-alsa && \
    cd /tmp/bluez-alsa && \
    autoreconf --install && \
    mkdir build && cd build && \
    # needs to match trimui OS layout
    # /usr/share/alsa/alsa.conf.d (matches alsa 1.16 and below)
    # /usr/share/dbus-1/system.d (default is correct)
    ../configure  \
        --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT/usr \
        --with-sysroot=$SYSROOT \
        --with-alsaconfdir=/usr/share/alsa/alsa.conf.d && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/bluez-alsa

# stuff and extra libs
COPY support .
#RUN ./build-libzip.sh > /tmp/libzip.log
#RUN ./build-bluez.sh > /tmp/bluez.log

# TODO: migrate 
# old               new
# BUILD_ARCH     -> CROSS_TRIPLE
ENV BUILD_ARCH=${CROSS_TRIPLE}
# PREFIX_LOCAL   -> do we still need it?
ENV PREFIX_LOCAL=/opt/nextui
# UNION_PLATFORM -> move to Dockerfile
ENV UNION_PLATFORM=tg5040

# just to make sure
RUN mkdir -p ${PREFIX_LOCAL}/include
RUN mkdir -p ${PREFIX_LOCAL}/lib

VOLUME /root/workspace
WORKDIR /workspace

CMD ["/bin/bash"]
