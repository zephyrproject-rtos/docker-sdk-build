#!/bin/bash

set -eo pipefail

# Parse arguments
fetch_type="${1:-all}"
op_type="$2"

if [ "${fetch_type}" == "toolchain" ]; then
  fetch_toolchain="y"
elif [ "${fetch_type}" == "all" ]; then
  fetch_toolchain="y"
else
  eval fetch_${fetch_type}="y"
fi

if [ "${fetch_toolchain}" == "y" ]; then
  fetch_binutils="y"
  fetch_gcc="y"
  fetch_mingw="y"
fi

if [ "${op_type}" != "fetch_only" ]; then
  op_extract="y"
fi

# Load component versions
source $(dirname "$(realpath $0)")/mingw-versions.in

# Create source directory
mkdir -p tarballs
mkdir -p src
cd src

# Process Binutils
if [ "${fetch_binutils}" == "y" ]; then
  BINUTILS_DIR="binutils-${BINUTILS_VERSION}"
  BINUTILS_FILE="../tarballs/binutils-${BINUTILS_VERSION}.tar.xz"

  if [ ! -f "${BINUTILS_FILE}" ]; then
    echo "@@@ Downloading Binutils tarball ..."
    wget -O ${BINUTILS_FILE} https://ftp.gnu.org/gnu/binutils/${BINUTILS_FILE}
  fi

  if [ ! -d "${BINUTILS_DIR}" ] && [ "${op_extract}" == "y" ]; then
    echo "@@@ Extracting Binutils tarball ..."
    tar Jxf ${BINUTILS_FILE}
  fi
fi

# Process GCC
if [ "${fetch_gcc}" == "y" ]; then
  GCC_DIR="gcc-${GCC_VERSION}"
  GCC_FILE="../tarballs/gcc-${GCC_VERSION}.tar.xz"

  if [ ! -f "${GCC_FILE}" ]; then
    echo "@@@ Downloading GCC tarball ..."
    wget -O ${GCC_FILE} https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_FILE}
  fi

  if [ ! -d "${GCC_DIR}" ] && [ "${op_extract}" == "y" ]; then
    echo "@@@ Extracting GCC tarball ..."
    tar Jxf ${GCC_FILE}

    echo "@@@ Downloading and extracting GCC prerequisites ..."
    pushd gcc-${GCC_VERSION}
    contrib/download_prerequisites
    popd
  fi
fi

# Process MinGW-w64
if [ "${fetch_mingw}" == "y" ]; then
  MINGW_DIR="mingw-w64-v${MINGW_VERSION}"
  MINGW_FILE="../tarballs/mingw-w64-v${MINGW_VERSION}.tar.bz2"

  if [ ! -f "${MINGW_FILE}" ]; then
    echo "@@@ Downloading MinGW-w64 tarball ..."
    wget -O ${MINGW_FILE} https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/${MINGW_FILE}
  fi

  if [ ! -d "${MINGW_DIR}" ] && [ "${op_extract}" == "y" ]; then
    echo "@@@ Extracting MinGW-w64 tarball ..."
    tar jxf ${MINGW_FILE}
  fi
fi
