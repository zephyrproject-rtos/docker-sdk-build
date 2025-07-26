FROM python:3.10-buster

ARG CMAKE_VERSION=3.30.5
ARG NINJA_VERSION=1.12.1
ARG QEMU_VERSION=8.2.2

ARG UID=1001
ARG GID=1001

# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

# Upgrade packages
RUN <<EOF
	sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list

	apt-get clean
	apt-get update
	apt-get upgrade -y
EOF

# software-properties for add-apt-repository
# locales for LANG support
# sudo to make life easier when running as build user
# vim.tiny so we have an editor
RUN <<EOF
	apt-get install -y --no-install-recommends \
		software-properties-common \
		locales \
		locales-all \
		sudo \
		vim.tiny
EOF

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# The package sets are based on Yocto & crosstool-ng docs/references:
#
# Yocto:
# https://www.yoctoproject.org/docs/2.3.4/ref-manual/ref-manual.html#ubuntu-packages
#
# crosstool-ng:
# https://github.com/crosstool-ng/crosstool-ng/blob/master/testing/docker/ubuntu18.04/Dockerfile
RUN <<EOF
	apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bison \
		build-essential \
		bzip2 \
		ca-certificates \
		chrpath \
		cpio \
		debianutils \
		diffstat \
		flex \
		g++ \
		gawk \
		gcc \
		gperf \
		help2man \
		iputils-ping \
		libncurses5-dev \
		libstdc++6 \
		libtool \
		libtool-bin \
		make \
		patch \
		python \
		python3 \
		python3-dev \
		python3-pexpect \
		python3-pip \
		python3-setuptools \
		socat \
		texinfo \
		unzip \
		wget \
		xz-utils
EOF

# Install packages for creating SDK packages
RUN <<EOF
	apt-get install -y --no-install-recommends \
		curl \
		makeself \
		p7zip-full \
		tree
EOF

# Install CMake
RUN <<EOF
	wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh
	chmod +x cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh
	./cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh --skip-license --prefix=/usr/local
	rm cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh
EOF

# Install ninja
RUN <<EOF
	NINJA_SUFFIX=$(case $HOSTTYPE in aarch64) echo "-aarch64";; esac)
	wget https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux${NINJA_SUFFIX}.zip
	unzip ninja-linux${NINJA_SUFFIX}.zip
	mv ninja /usr/local/bin
	rm ninja-linux${NINJA_SUFFIX}.zip
EOF

# Install Python packages
RUN <<EOF
	# Install awscli for uploading to AWS S3
	pip3 install awscli

	# Install meson for building picolibc
	pip3 install meson
EOF

# Install MinGW-w64 toolchain
RUN --mount=source=mingw/tarballs,target=/mingw/tarballs \
    --mount=source=mingw/scripts,target=/mingw/scripts \
    <<EOF
	pushd /mingw
	scripts/mingw-fetch.sh toolchain
	scripts/mingw-build-toolchain.sh
	popd
	rm -rf /mingw/src /mingw/build
EOF

# Install QEMU for libc testing
RUN <<EOF
	wget https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz
	tar Jxf qemu-${QEMU_VERSION}.tar.xz
	pushd qemu-${QEMU_VERSION}
	./configure --target-list="aarch64-softmmu,arm-softmmu,riscv32-softmmu,riscv64-softmmu"
	make -j$(nproc)
	make install
	popd
	rm -rf qemu-${QEMU_VERSION}
	rm qemu-${QEMU_VERSION}.tar.xz
EOF

# Add build-agent user
RUN <<EOF
	groupadd -g $GID -o build-agent
	useradd -u $UID -m -g build-agent build-agent --shell /bin/bash
	echo 'build-agent ALL = NOPASSWD: ALL' > /etc/sudoers.d/build-agent
	chmod 0440 /etc/sudoers.d/build-agent
EOF

# NOTE: Do not switch to a non-root user because this creates all sorts of
#       permission-related problems with the GitHub Actions runner.
# USER build-agent
