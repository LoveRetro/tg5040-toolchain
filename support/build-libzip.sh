#! /bin/sh

mkdir -p ~/builds && cd ~/builds
git clone --depth 1 --branch "v1.11.3" https://github.com/nih-at/libzip.git 
mkdir -p libzip/build && cd libzip/build
cmake ..
make
make install