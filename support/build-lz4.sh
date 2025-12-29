#! /bin/bash

set -euo pipefail

# lz4
git clone --depth=1 --branch v1.10.0 https://github.com/lz4/lz4.git /tmp/lz4 && \
    cd /tmp/lz4 && \
    make CC=$CC PREFIX=$SYSROOT/usr -j$(nproc) && \
    make CC=$CC PREFIX=$SYSROOT/usr install && \
    cd /tmp && rm -rf /tmp/lz4
