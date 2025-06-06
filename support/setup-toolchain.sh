#! /bin/sh

SYSROOT_TAR="SDK_usr_tg5040_a133p"
TOOLCHAIN_NAME="aarch64-linux-gnu"
TOOLCHAIN_TAR="gcc-arm-8.3-2019.02-x86_64-aarch64-linux-gnu"

TOOLCHAIN_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.02/$TOOLCHAIN_TAR.tar.xz"
SYSROOT_URL="https://github.com/trimui/toolchain_sdk_smartpro/releases/download/20231018/$SYSROOT_TAR.tgz"

cd ~

TOOLCHAIN_ARCH=`uname -m`
if [ "$TOOLCHAIN_ARCH" = "aarch64" ]; then
	wget $SYSROOT_URL

	tar xf $SYSROOT_TAR.tgz
	rsync -a --ignore-existing ./usr/ /usr/
	rm -rf ./usr $SYSROOT_TAR.tgz
else 
	wget $TOOLCHAIN_URL
	wget $SYSROOT_URL

	tar xf $TOOLCHAIN_TAR.tar.xz -C /opt
	mv /opt/$TOOLCHAIN_TAR /opt/$TOOLCHAIN_NAME
	rm $TOOLCHAIN_TAR.tar.xz

	tar xf $SYSROOT_TAR.tgz
	rsync -a --ignore-existing ./usr/ /opt/$TOOLCHAIN_NAME/$TOOLCHAIN_NAME/libc/usr/
	rm -rf ./usr $SYSROOT_TAR.tgz
    
    # make sure cross compile libs are picked up by mingw-compiled toolchains
    mkdir -p /opt/$TOOLCHAIN_NAME/$TOOLCHAIN_NAME/libc/etc/
    cat /etc/ld.so.conf.d/$TOOLCHAIN_NAME.conf > /opt/$TOOLCHAIN_NAME/$TOOLCHAIN_NAME/libc/etc/ld.so.conf
    cat /etc/ld.so.conf.d/libc.conf >> /opt/$TOOLCHAIN_NAME/$TOOLCHAIN_NAME/libc/etc/ld.so.conf
fi