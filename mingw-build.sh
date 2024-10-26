#!/bin/bash

set -euo pipefail

BINUTILS_VERSION=2.42
GCC_VERSION=13.2.0
MINGW_VERSION=12.0.0

mkdir mingw
pushd mingw

# Download source code
echo "@@@ Downloading source code"
mkdir src
pushd src
## Binutils
wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz
tar Jxf binutils-${BINUTILS_VERSION}.tar.xz
## GCC
wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz
tar Jxf gcc-${GCC_VERSION}.tar.xz
pushd gcc-${GCC_VERSION}
contrib/download_prerequisites
popd
## MinGW-w64
wget https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v${MINGW_VERSION}.tar.bz2
tar jxf mingw-w64-v${MINGW_VERSION}.tar.bz2
popd

build_mingw_toolchain() {
  local old_path=$PATH
  local thread_model=$1
  local prefix=/opt/mingw-w64-${thread_model}

  echo "@@@ Building MinGW-w64 toolchain with '${thread_model}' thread model"
  
  # Add prefix bin directory to PATH to aid toolchain discovery
  export PATH="${prefix}/bin:${PATH}"

  # Create build directory
  mkdir build-${thread_model}
  pushd build-${thread_model}

  # Build Binutils
  mkdir binutils
  pushd binutils
  ../../src/binutils-${BINUTILS_VERSION}/configure \
    --prefix=${prefix} \
    --target=x86_64-w64-mingw32 \
    --disable-multilib
  make -j$(nproc)
  make install
  popd

  # Install MinGW headers
  mkdir mingw-headers
  pushd mingw-headers
  ../../src/mingw-w64-v${MINGW_VERSION}/mingw-w64-headers/configure \
    --prefix=${prefix}/x86_64-w64-mingw32 \
    --host=x86_64-w64-mingw32 \
    --with-default-msvcrt=ucrt
  make install
  popd

  # Build core GCC
  mkdir gcc
  pushd gcc
  ../../src/gcc-${GCC_VERSION}/configure \
    --prefix=${prefix} \
    --target=x86_64-w64-mingw32 \
    --disable-multilib \
    --enable-languages=c,c++ \
    --enable-threads=${thread_model} \
    --with-headers
  make -j$(nproc) all-gcc
  make install-gcc
  popd

  # Build MinGW
  mkdir mingw
  pushd mingw
  ../../src/mingw-w64-v${MINGW_VERSION}/configure \
    --prefix=${prefix}/x86_64-w64-mingw32 \
    --host=x86_64-w64-mingw32 \
    --with-default-msvcrt=ucrt
  make -j$(nproc)
  make install -j$(nproc)
  popd

  # Build MinGW winpthreads
  mkdir mingw-winpthreads
  pushd mingw-winpthreads
  ../../src/mingw-w64-v${MINGW_VERSION}/mingw-w64-libraries/winpthreads/configure \
    --prefix=${prefix}/x86_64-w64-mingw32 \
    --host=x86_64-w64-mingw32
  make -j$(nproc)
  make install
  popd

  # Build final GCC
  pushd gcc
  make -j$(nproc)
  make install
  popd

  # Place libwinpthread-1.dll in 'lib' directory so that it can be discovered
  # using 'clang -print-file-name=libwinpthread-1.dll'.
  pushd ${prefix}/x86_64-w64-mingw32
  cp bin/libwinpthread-1.dll lib
  popd

  # Restore environment
  popd
  export PATH=${old_path}
}

# Build MinGW toolchain with 'win32' thread model
build_mingw_toolchain win32

# Build MinGW toolchain with 'posix' thread model
build_mingw_toolchain posix

# Clean up build directories
popd
rm -rf mingw
