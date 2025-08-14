#! /bin/bash

set -euo pipefail

# bluez
# 5.80 contains a reference to rl_clear_visible_line, which would require a newer ncurses/tinfo
# 5.79 changes to obexd/client/bip-common cause some warnings/errors
# 5.78 works
git clone --depth 1 --branch 5.78 https://github.com/bluez/bluez.git /tmp/bluez && \
    cd /tmp/bluez && \
    sed -i 's/-lreadline\b/-lreadline -L\/usr\/lib -lncurses/g' Makefile.tools && \
    ./bootstrap && \
    ./configure \
        --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT/usr \
        --disable-systemd \
        --disable-udev \
        --disable-cups \
        --disable-manpages \
        --with-sysroot=$SYSROOT && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf /tmp/bluez

# libsbc
# not sure how thats possible, but the libsbc that trimui is shipping (and claims to be 1.2.1)
# does not export a sbc_reinit_a2dp - which is the whole point of 1.2.x.
git clone --depth 1 --branch 2.1 https://git.kernel.org/pub/scm/bluetooth/sbc.git /tmp/sbc && \
    cd /tmp/sbc && \
    autoreconf --install && \
    mkdir build && cd build && \
    ../configure  \
        --host=$CROSS_TRIPLE \
        --prefix=$SYSROOT/usr \
        --with-sysroot=$SYSROOT && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf /tmp/sbc

# bluez-alsa
# 4.1.0 this is the latest we can build without replacing glib 2.50.1 and sbc 1.2.1
# 4.1.1 misses gdbus-codegen
git clone --depth 1 --branch v4.1.0 https://github.com/arkq/bluez-alsa.git /tmp/bluez-alsa && \
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
    cd /tmp && rm -rf /tmp/bluez-alsa

# deploy to device and replace stock libs
## for bluez-alsa:
## /usr/lib/alsa-lib/libasound_module_ctl_bluealsa.so
## /usr/lib/alsa-lib/libasound_module_pcm_bluealsa.so
## /usr/bin/bluealsa
## /usr/bin/bluealsa-aplay
## /etc/dbus-1/system.d/bluealsa.conf
## /usr/share/alsa/alsa.conf.d/20-bluealsa.conf
## for bluez:
## /usr/lib/libbluetooth.so.3.19.15
## ln -s -f libbluetooth.so.3.19.15 libbluetooth.so.3
## ln -s -f libbluetooth.so.3.19.15 libbluetooth.so
## /usr/bin/bluetoothctl
## /usr/bin/btmon
## /usr/bin/rctest
## /usr/bin/l2test
## /usr/bin/l2ping
## /usr/bin/bluemoon
## /usr/bin/hex2hcd
## /usr/bin/mpris-proxy
## /usr/bin/btattach
## /usr/bin/isotest
## for sbc:
## /usr/lib/libsbc.so.1.3.1
## ln -s -f libsbc.so.1.3.1 libsbc.so.1
## ln -s -f libsbc.so.1.3.1 libsbc.so
## /usr/bin/sbcinfo
## /usr/bin/sbcdec
## /usr/bin/sbcenc