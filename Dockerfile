FROM ubuntu:24.04

# Install base build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
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
    && rm -rf /var/lib/apt/lists/*

ENV TOOLCHAIN_DIR=/opt/toolchain

# Download the appropriate cross toolchain based on host arch
RUN mkdir -p ${TOOLCHAIN_DIR} && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        TOOLCHAIN_URL=https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        TOOLCHAIN_URL=https://github.com/frysee/gcc-arm-8.3-aarch64/releases/download/0.0.3/gcc-arm-8.3-2019.03-aarch64-arm-linux-gnueabihf.tar.xz; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -q $TOOLCHAIN_URL -O /tmp/toolchain.tar.xz && \
    tar -xf /tmp/toolchain.tar.xz -C ${TOOLCHAIN_DIR} --strip-components=1 && \
    rm /tmp/toolchain.tar.xz

ENV CROSS_TRIPLE=arm-linux-gnueabihf
#ENV CROSS_TRIPLE=aarch64-linux-gnu

# Download and extract the SDK sysroot
#ENV SYSROOT_DIR=${TOOLCHAIN_DIR}/${CROSS_TRIPLE}/sysroot
#ENV SDK_TAR=SDK_usr_tg5040_a133p.tgz
#ENV SDK_URL=https://github.com/trimui/toolchain_sdk_smartpro/releases/download/20231018/${SDK_TAR}
#
#RUN mkdir -p ${SYSROOT_DIR} && \
#    wget -q ${SDK_URL} -O /tmp/${SDK_TAR} && \
#    tar -xzf /tmp/${SDK_TAR} -C ${SYSROOT_DIR} && \
#    rm /tmp/${SDK_TAR}

# Build tools

ENV CROSS_ROOT=${TOOLCHAIN_DIR}
ENV AS=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-as \
    AR=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ar \
    CC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gcc \
    CPP=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-cpp \
    CXX=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-g++ \
    LD=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ld \
    FC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gfortran
# deprecated, remove
#ENV SYSROOT=${SYSROOT_DIR}

# qemu, anyone?
ENV QEMU_LD_PREFIX="${CROSS_ROOT}/${CROSS_TRIPLE}/sysroot"
ENV QEMU_SET_ENV="LD_LIBRARY_PATH=${CROSS_ROOT}/lib:${QEMU_LD_PREFIX}"

COPY toolchain-aarch64.cmake ${CROSS_ROOT}/Toolchain.cmake
ENV CMAKE_TOOLCHAIN_FILE=${CROSS_ROOT}/Toolchain.cmake

#ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=${SYSROOT_DIR}
ENV PKG_CONFIG_PATH=${SYSROOT_DIR}/usr/lib/pkgconfig:${SYSROOT_DIR}/usr/share/pkgconfig

# Linux kernel cross compilation variables
ENV PATH=${PATH}:${CROSS_ROOT}/bin
ENV CROSS_COMPILE=${CROSS_TRIPLE}-
ENV ARCH=arm64

# for c
#ENV CFLAGS="--sysroot=${SYSROOT_DIR}"
#ENV CXXFLAGS="--sysroot=${SYSROOT_DIR}"
#ENV LDFLAGS="--sysroot=${SYSROOT_DIR}"

# lzma/xz
RUN git clone https://github.com/tukaani-project/xz.git /tmp/xz && \
    cd /tmp/xz && \
    ./autogen.sh && \
    ./configure \
        --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT_DIR/usr \
        --disable-static \
        --enable-shared \
        --with-sysroot=$SYSROOT_DIR && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/xz

# zstd
RUN git clone --depth=1 https://github.com/facebook/zstd.git /tmp/zstd && \
    cd /tmp/zstd/build/cmake && \
    cmake . \
        -DCMAKE_INSTALL_PREFIX=$SYSROOT_DIR/usr \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/zstd

# bz2
# qemu-arm: Could not open '/lib/ld-linux-armhf.so.3': No such file or directory
#RUN wget -q https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz -O /tmp/bzip2.tar.gz && \
#    cd /tmp && tar -xzf bzip2.tar.gz && cd bzip2-1.0.8 && \
#    make CC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gcc AR=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ar \
#         RANLIB=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ranlib -j$(nproc) && \
#    make PREFIX=$SYSROOT_DIR/usr install && \
#    rm -rf /tmp/bzip2*

# libzip
# /buildroot/arm-linux-gnueabihf/sysroot/usr/lib/libbz2.so: file not recognized: file format not recognized
#RUN git clone https://github.com/nih-at/libzip.git /tmp/libzip && \
#    mkdir /tmp/libzip/build && cd /tmp/libzip/build && \
#    cmake .. \
#        -DCMAKE_INSTALL_PREFIX=$SYSROOT_DIR/usr \
#        -DCMAKE_BUILD_TYPE=Release && \
#    make -j$(nproc) && make install && \
#    rm -rf /tmp/libzip

# bluez
# 5.80 contains a reference to rl_clear_visible_line, which would require a newer ncurses/tinfo
# 5.79 changes to obexd/client/bip-common cause some warnings/errors
# 5.78 works
#RUN git clone --depth 1 --branch 5.78 https://github.com/bluez/bluez.git /tmp/bluez && \
#    cd /tmp/bluez && \
#    ./bootstrap && \
#    ./configure \
#        --host=$CROSS_TRIPLE \
#        --prefix=$SYSROOT_DIR/usr \
#        --disable-systemd \
#        --disable-udev \
#        --disable-cups \
#        --disable-obex \
#        --disable-manpages \
#        --with-sysroot=$SYSROOT_DIR && \
#        CPPFLAGS="-I$SYSROOT_DIR/usr/include/readline" \
#    make -j$(nproc) && make install && \
#    rm -rf /tmp/bluez

#./configure \
#  --host=$CROSS_TRIPLE \
#  --prefix=$SYSROOT_DIR/usr \
#  --disable-systemd \
#  --disable-udev \
#  --disable-cups \
#  --disable-obex \
#  --disable-manpages \
#  --sysroot=$SYSROOT_DIR \
#  CPPFLAGS="-I$SYSROOT_DIR/usr/include/readline" \
#  LDFLAGS="-L$SYSROOT_DIR/usr/lib"

WORKDIR /workspace
