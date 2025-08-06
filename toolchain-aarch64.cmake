set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(cross_triple $ENV{CROSS_TRIPLE})
set(cross_root $ENV{CROSS_ROOT})

set(CMAKE_C_COMPILER $ENV{CC})
set(CMAKE_CXX_COMPILER $ENV{CXX})
set(CMAKE_Fortran_COMPILER $ENV{FC})

set(CMAKE_CXX_FLAGS "-I ${cross_root}/include/")

list(APPEND CMAKE_FIND_ROOT_PATH ${CMAKE_PREFIX_PATH} ${cross_root} ${cross_root}/${cross_triple})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

#set(CMAKE_SYSROOT ${cross_root}/${cross_triple}/sysroot)

set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/qemu-aarch64)

# Optionally tell CMake how to pass sysroot to the compiler
# These lines are usually not required if your compiler is already configured
# properly with --sysroot support, which ARM toolchains usually are.
#set(CMAKE_C_FLAGS "--sysroot=${CMAKE_SYSROOT}")
#set(CMAKE_CXX_FLAGS "--sysroot=${CMAKE_SYSROOT}")
#set(CMAKE_CXX_FLAGS "--sysroot=${CMAKE_SYSROOT}")