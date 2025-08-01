set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_SYSROOT /opt/sdk)

set(tools /opt/toolchain)

set(CMAKE_C_COMPILER ${tools}/bin/arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER ${tools}/bin/arm-linux-gnueabihf-g++)

# Optionally tell CMake how to pass sysroot to the compiler
# These lines are usually not required if your compiler is already configured
# properly with --sysroot support, which ARM toolchains usually are.
# set(CMAKE_C_FLAGS "--sysroot=${CMAKE_SYSROOT}")
# set(CMAKE_CXX_FLAGS "--sysroot=${CMAKE_SYSROOT}")

set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)