#!/bin/bash

set -eo pipefail

# Parse arguments
fetch_type="${1:-all}"
op_type="$2"

if [ "${fetch_type}" == "toolchain" ]; then
  fetch_toolchain="y"
elif [ "${fetch_type}" == "lib" ]; then
  fetch_lib="y"
elif [ "${fetch_type}" == "all" ]; then
  fetch_toolchain="y"
  fetch_lib="y"
else
  eval fetch_${fetch_type}="y"
fi

if [ "${fetch_toolchain}" == "y" ]; then
  fetch_binutils="y"
  fetch_gcc="y"
  fetch_mingw="y"
fi

if [ "${fetch_lib}" == "y" ]; then
  fetch_libiconv="y"
  fetch_libunistring="y"
  fetch_gettext="y"
  fetch_gmp="y"
  fetch_zlib="y"
  fetch_libpng="y"
  fetch_libjpeg_turbo="y"
  fetch_pixman="y"
  fetch_glib="y"
  fetch_libgpg_error="y"
  fetch_libgcrypt="y"
  fetch_libusb="y"
  fetch_hidapi_hidapi="y"
  fetch_libftdi1="y"
  fetch_boost="y"
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

# Process toolchain components
## Process Binutils
if [ "${fetch_binutils}" == "y" ]; then
  BINUTILS_DIR="binutils-${BINUTILS_VERSION}"
  BINUTILS_FILE="../tarballs/binutils-${BINUTILS_VERSION}.tar.xz"

  if [ ! -f "${BINUTILS_FILE}" ]; then
    echo "@@@ Downloading Binutils tarball ..."
    wget -O ${BINUTILS_FILE} https://ftp.gnu.org/gnu/binutils/$(basename ${BINUTILS_FILE})
  fi

  if [ ! -d "${BINUTILS_DIR}" ] && [ "${op_extract}" == "y" ]; then
    echo "@@@ Extracting Binutils tarball ..."
    tar Jxf ${BINUTILS_FILE}
  fi
fi

## Process GCC
if [ "${fetch_gcc}" == "y" ]; then
  GCC_DIR="gcc-${GCC_VERSION}"
  GCC_FILE="../tarballs/gcc-${GCC_VERSION}.tar.xz"

  if [ ! -f "${GCC_FILE}" ]; then
    echo "@@@ Downloading GCC tarball ..."
    wget -O ${GCC_FILE} https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/$(basename ${GCC_FILE})
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

## Process MinGW-w64
if [ "${fetch_mingw}" == "y" ]; then
  MINGW_DIR="mingw-w64-v${MINGW_VERSION}"
  MINGW_FILE="../tarballs/mingw-w64-v${MINGW_VERSION}.tar.bz2"

  if [ ! -f "${MINGW_FILE}" ]; then
    echo "@@@ Downloading MinGW-w64 tarball ..."
    wget -O ${MINGW_FILE} https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/$(basename ${MINGW_FILE})
  fi

  if [ ! -d "${MINGW_DIR}" ] && [ "${op_extract}" == "y" ]; then
    echo "@@@ Extracting MinGW-w64 tarball ..."
    tar jxf ${MINGW_FILE}
  fi
fi

# Process library components
process_lib()
{
  local component=$1
  local version=$2
  local tarball_uri=$3
  local fetch_var="fetch_${component//-/_}"

  if [ "${!fetch_var}" == "y" ]; then
    local src_dir="${component}-${version}"
    local src_file="../tarballs/$(basename "${tarball_uri}")"

    if [ ! -f "${src_file}" ]; then
      echo "@@@ Downloading ${component} tarball ..."
      wget -O ${src_file} ${tarball_uri}
    fi

    if [ ! -d "${src_dir}" ] && [ "${op_extract}" == "y" ]; then
      echo "@@@ Extracting ${component} tarball ..."
      tar xf ${src_file}
    fi
  fi
}

## Process libiconv
process_lib \
  libiconv \
  ${LIBICONV_VERSION} \
  https://ftp.gnu.org/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz

## Process libunistring
process_lib \
  libunistring \
  ${LIBUNISTRING_VERSION} \
  https://ftp.gnu.org/gnu/libunistring/libunistring-${LIBUNISTRING_VERSION}.tar.xz

## Process gettext
process_lib \
  gettext \
  ${GETTEXT_VERSION} \
  https://ftp.gnu.org/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.xz

## Process gmp
process_lib \
  gmp \
  ${GMP_VERSION} \
  https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz

## Process zlib
process_lib \
  zlib \
  ${ZLIB_VERSION} \
  https://zlib.net/zlib-${ZLIB_VERSION}.tar.xz

## Process libpng
process_lib \
  libpng \
  ${LIBPNG_VERSION} \
  https://download.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.xz

## Process libjpeg-turbo
process_lib \
  libjpeg-turbo \
  ${LIBJPEG_TURBO_VERSION} \
  https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${LIBJPEG_TURBO_VERSION}/libjpeg-turbo-${LIBJPEG_TURBO_VERSION}.tar.gz

## Process pixman
process_lib \
  pixman \
  ${PIXMAN_VERSION} \
  https://cairographics.org/releases/pixman-${PIXMAN_VERSION}.tar.gz

## Process glib
process_lib \
  glib \
  ${GLIB_VERSION} \
  https://download.gnome.org/sources/glib/${GLIB_VERSION%.*}/glib-${GLIB_VERSION}.tar.xz

## Process libgpg-error
process_lib \
  libgpg-error \
  ${LIBGPG_ERROR_VERSION} \
  https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${LIBGPG_ERROR_VERSION}.tar.bz2

## Process libgcrypt
process_lib \
  libgcrypt \
  ${LIBGCRYPT_VERSION} \
  https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2

## Process libusb
process_lib \
  libusb \
  ${LIBUSB_VERSION} \
  https://github.com/libusb/libusb/releases/download/v${LIBUSB_VERSION}/libusb-${LIBUSB_VERSION}.tar.bz2

## Process hidapi
process_lib \
  hidapi-hidapi \
  ${HIDAPI_VERSION} \
  https://github.com/libusb/hidapi/archive/refs/tags/hidapi-${HIDAPI_VERSION}.tar.gz

## Process libftdi
process_lib \
  libftdi1 \
  ${LIBFTDI_VERSION} \
  https://www.intra2net.com/en/developer/libftdi/download/libftdi1-${LIBFTDI_VERSION}.tar.bz2

## Process boost
process_lib_boost()
{
  local src_dir="boost_${BOOST_VERSION//./_}"
  local src_file="../tarballs/boost_${BOOST_VERSION//./_}.tar.bz2"

  if [ ! -f "${src_file}" ]; then
    echo "@@@ Downloading boost tarball ..."
    wget \
      -O ${src_file} \
      https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.bz2
  fi

  if [ ! -d "${src_dir}" ] && [ "${op_extract}" == "y" ]; then
    echo "@@@ Extracting boost tarball ..."
    tar xf ${src_file}
  fi
}

if [ "${fetch_boost}" == "y" ]; then
  process_lib_boost
fi
