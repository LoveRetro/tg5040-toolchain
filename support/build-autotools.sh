#! /bin/sh

mkdir -p ~/builds && cd ~/builds

wget https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz
tar -xzf m4-1.4.19.tar.gz
cd m4-1.4.19
./configure --prefix=/usr/local
make
make install
cd ..

wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
tar -xzf autoconf-2.71.tar.gz
cd autoconf-2.71
./configure --prefix=/usr/local
make
make install
cd ..

wget https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz
tar -xzf automake-1.16.5.tar.gz
cd automake-1.16.5
./configure --prefix=/usr/local
make
make install
cd ..

wget https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.gz
tar -xzf libtool-2.4.7.tar.gz
cd libtool-2.4.7
./configure --prefix=/usr/local
make
make install
cd ..