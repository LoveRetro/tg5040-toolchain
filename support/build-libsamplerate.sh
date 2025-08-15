#! /bin/bash

set -euo pipefail

# libsamplerate
git clone --depth=1 --branch 0.2.2 https://github.com/libsndfile/libsamplerate.git /tmp/samplerate && \
    cd /tmp/samplerate && \
    mkdir build && cd build && \
    cmake .. \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=$SYSROOT/usr \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf /tmp/samplerate