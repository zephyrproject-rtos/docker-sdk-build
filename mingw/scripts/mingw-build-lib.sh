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
  --enable-static
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
  --enable-static \
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
  --enable-static \
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
  --enable-static \
  --disable-shared \
  --enable-cxx
make -j$(nproc)
make install
popd

# Build zlib
mkdir zlib
pushd zlib
CHOST=${mingw_triplet} ../../src/zlib-${ZLIB_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --static
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
  --enable-static
make -j$(nproc)
make install
popd

# Build libjpeg-turbo
mkdir libjpeg-turbo
pushd libjpeg-turbo
cmake \
  -GNinja \
  -DCMAKE_INSTALL_PREFIX=${mingw_sysroot} \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_PROCESSOR=AMD64 \
  -DCMAKE_C_COMPILER=${mingw_triplet}-gcc \
  -DCMAKE_RC_COMPILER=${mingw_triplet}-windres \
  -DWITH_JPEG8=ON \
  -DENABLE_SHARED=ON \
  -DENABLE_STATIC=ON \
  ../../src/libjpeg-turbo-${LIBJPEG_TURBO_VERSION}
cmake --build .
cmake --install .
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
  -Dlibpng=disabled \
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
  --default-library=static \
  ../../src/glib-${GLIB_VERSION}
meson compile
meson install
ln -s ${mingw_sysroot}/bin/gdbus-codegen ${mingw_bin}/gdbus-codegen
popd

# Build libgpg-error
mkdir libgpg-error
pushd libgpg-error
../../src/libgpg-error-${LIBGPG_ERROR_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --enable-static \
  --enable-install-gpg-error-config
make -j$(nproc)
make install
popd

# Build libgcrypt
mkdir libgcrypt
pushd libgcrypt
../../src/libgcrypt-${LIBGCRYPT_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --enable-static
make -j$(nproc)
make install
popd

# Build libusb
mkdir libusb
pushd libusb
../../src/libusb-${LIBUSB_VERSION}/configure \
  --prefix=${mingw_sysroot} \
  --host=${mingw_triplet} \
  --enable-shared \
  --enable-static
make -j$(nproc)
make install
popd

# Build hidapi
mkdir hidapi
pushd hidapi
cmake \
  -DCMAKE_INSTALL_PREFIX=${mingw_sysroot} \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_PROCESSOR=AMD64 \
  -DCMAKE_C_COMPILER=${mingw_triplet}-gcc \
  ../../src/hidapi-hidapi-${HIDAPI_VERSION}
cmake --build .
cmake --install .
popd

# Build libftdi
mkdir libftdi
pushd libftdi
cmake \
  -DCMAKE_INSTALL_PREFIX=${mingw_sysroot} \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_PROCESSOR=AMD64 \
  -DCMAKE_C_COMPILER=${mingw_triplet}-gcc \
  -DBUILD_TESTS=OFF \
  -DDOCUMENTATION=OFF \
  ../../src/libftdi1-${LIBFTDI_VERSION}
cmake --build .
cmake --install .
popd

# Build boost
cp -R ../src/boost_${BOOST_VERSION//./_} boost
pushd boost

./bootstrap.sh \
  --with-toolset=gcc \
  --with-libraries=regex \
  --without-icu

sed -i \
  "s/using gcc ;/using gcc : mingw : ${mingw_triplet}-g++ ;/g" \
  project-config.jam

./b2 install \
  toolset=gcc-mingw \
  link=static \
  threading=multi \
  variant=release \
  --prefix=${mingw_sysroot}

popd
