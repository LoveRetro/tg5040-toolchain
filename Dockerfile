FROM ubuntu:24.04

# Install base build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    autotools-dev \
    autoconf \
    automake \
    libtool \
    m4 \
    pkg-config \
    unzip \
    wget \
    git \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Define variables
ENV TOOLCHAIN_DIR=/opt/toolchain
ENV SYSROOT_DIR=/opt/sdk
ENV SDK_TAR=SDK_usr_tg5040_a133p.tgz
ENV SDK_URL=https://github.com/trimui/toolchain_sdk_smartpro/releases/download/20231018/${SDK_TAR}

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

# Download and extract the SDK sysroot
RUN mkdir -p ${SYSROOT_DIR} && \
    wget -q ${SDK_URL} -O /tmp/${SDK_TAR} && \
    tar -xzf /tmp/${SDK_TAR} -C ${SYSROOT_DIR} && \
    rm /tmp/${SDK_TAR}

# Environment variables for build
ENV PATH=${TOOLCHAIN_DIR}/bin:$PATH
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV CC=${CROSS_COMPILE}gcc
ENV CXX=${CROSS_COMPILE}g++
ENV SYSROOT=${SYSROOT_DIR}
ENV CFLAGS="--sysroot=${SYSROOT}"
ENV CXXFLAGS="--sysroot=${SYSROOT}"
ENV LDFLAGS="--sysroot=${SYSROOT}"

# Create CMake toolchain file
COPY toolchain-aarch64.cmake /workspace/

# Build additional libraries like libzip
#RUN git clone https://github.com/nih-at/libzip.git /tmp/libzip && \
#    mkdir /tmp/libzip/build && cd /tmp/libzip/build && \
#    cmake .. \
#        -DCMAKE_TOOLCHAIN_FILE=/workspace/toolchain-aarch64.cmake \
#        -DCMAKE_INSTALL_PREFIX=$SYSROOT/usr \
#        -DCMAKE_BUILD_TYPE=Release && \
#    make -j$(nproc) && make install

WORKDIR /workspace
