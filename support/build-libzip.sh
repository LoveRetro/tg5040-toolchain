#! /bin/bash

set -euo pipefail

# lzma/xz
git clone https://github.com/tukaani-project/xz.git /tmp/xz && \
    cd /tmp/xz && \
    ./autogen.sh && \
    ./configure \
       --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT/usr \
        --disable-static \
        --enable-shared \
        --with-sysroot=$SYSROOT && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf /tmp/xz

# zstd
git clone --depth=1 https://github.com/facebook/zstd.git /tmp/zstd && \
    cd /tmp/zstd/build/cmake && \
    cmake . \
        -DCMAKE_INSTALL_PREFIX=$SYSROOT/usr \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf /tmp/zstd

# bz2
wget -q https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz -O /tmp/bzip2.tar.gz && \
    cd /tmp && tar -xzf bzip2.tar.gz && cd bzip2-1.0.8 && \
    make -j$(nproc) && \
    make PREFIX=$SYSROOT/usr install && \
    cd /tmp && rm -rf /tmp/bzip2*

# libzip
git clone https://github.com/nih-at/libzip.git /tmp/libzip && \
    mkdir /tmp/libzip/build && cd /tmp/libzip/build && \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=$SYSROOT/usr \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf /tmp/libzip