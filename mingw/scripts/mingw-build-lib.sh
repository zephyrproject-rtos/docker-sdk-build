#!/bin/bash

set -euo pipefail

# Load component versions
source $(dirname "$(realpath $0)")/mingw-versions.in

# Create build directory
mkdir -p build
cd build

mingw_base="/opt/mingw-w64-win32"
mingw_triplet="x86_64-w64-mingw32"
mingw_bin="${mingw_base}/bin"
mingw_sysroot="${mingw_base}/${mingw_triplet}"

# Add MinGW-w64 toolchain bin directory to PATH to aid toolchain discovery
export PATH="${mingw_bin}:${PATH}"

# Configure pkg-config for MinGW-w64
mingw_pkgconfig="${mingw_bin}/${mingw_triplet}-pkg-config"
export PKG_CONFIG_PATH=${mingw_sysroot}/lib/pkgconfig
[ ! -f "${mingw_pkgconfig}" ] && ln -sf /usr/bin/pkg-config ${mingw_pkgconfig}

# Build libiconv
mkdir libiconv
pushd libiconv
../../src/libiconv-${LIBICONV_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static
make -j$(nproc)
make install
popd

# Build libunistring
mkdir libunistring
pushd libunistring
../../src/libunistring-${LIBUNISTRING_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static \
  --enable-threads=windows
make -j$(nproc)
make install
popd

# Build gettext
mkdir gettext
pushd gettext
../../src/gettext-${GETTEXT_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static \
  --enable-threads=win32 \
  --disable-java \
  --disable-java-native \
  --disable-csharp \
  --disable-doc
make -j$(nproc)
make install
popd

# Build gmp
mkdir gmp
pushd gmp
../../src/gmp-${GMP_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static \
  --enable-cxx
make -j$(nproc)
make install
popd

# Build zlib
mkdir zlib
pushd zlib
CHOST=${mingw_triplet} ../../src/zlib-${ZLIB_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --shared
make -j$(nproc)
make install
popd

# Build libpng
mkdir libpng
pushd libpng
../../src/libpng-${LIBPNG_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static
make -j$(nproc)
make install
popd

# Build pixman
mkdir pixman
pushd pixman
meson setup \
  --cross-file=../../scripts/cross-${mingw_triplet}.txt \
  --prefix=${mingw_sysroot} \
  --buildtype=plain \
  -Ddefault_library=both \
  -Dgtk=disabled \
  ../../src/pixman-${PIXMAN_VERSION}
meson compile
meson install
popd

# Build glib
mkdir glib
pushd glib
meson setup \
  --cross-file=../../scripts/cross-${mingw_triplet}.txt \
  --prefix=${mingw_sysroot} \
  --buildtype=release \
  -Dlibelf=disabled \
  --default-library=shared \
  ../../src/glib-${GLIB_VERSION}
meson compile
meson install
ln -s ${mingw_sysroot}/bin/gdbus-codegen ${mingw_bin}/gdbus-codegen
popd

# Build nettle
mkdir nettle
pushd nettle
../../src/nettle-${NETTLE_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static \
  --enable-public-key
make -j$(nproc)
make install
popd

# Build libtasn1
mkdir libtasn1
pushd libtasn1
../../src/libtasn1-${LIBTASN1_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static
make -j$(nproc)
make install
popd

# Build libidn2
mkdir libidn2
pushd libidn2
../../src/libidn2-${LIBIDN2_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static
make -j$(nproc)
make install
popd

# Build gnutls
mkdir gnutls
pushd gnutls
../../src/gnutls-${GNUTLS_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --disable-static \
  --enable-cxx \
  --enable-openssl-compatibility \
  --disable-libdane \
  --disable-tests \
  --disable-doc \
  --without-p11-kit
make -j$(nproc)
make install
popd
