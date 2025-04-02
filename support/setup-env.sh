TOOLCHAIN_ARCH=`uname -m`
export BUILD_ARCH=aarch64-linux-gnu
if [ "$TOOLCHAIN_ARCH" = "aarch64" ]; then
	export CROSS_COMPILE=/usr/bin/${BUILD_ARCH}-
	export PREFIX=/usr
else
	export PATH="/opt/${BUILD_ARCH}/${BUILD_ARCH}/bin:${PATH}:/opt/${BUILD_ARCH}/${BUILD_ARCH}/libc/bin"
	export CROSS_COMPILE=/opt/${BUILD_ARCH}/bin/${BUILD_ARCH}-
	export PREFIX=/opt/${BUILD_ARCH}/${BUILD_ARCH}/libc/usr
fi
export UNION_PLATFORM=tg5040
