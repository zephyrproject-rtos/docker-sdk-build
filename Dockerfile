FROM python:3.12.10-bullseye

ARG CMAKE_VERSION=3.30.5
ARG NINJA_VERSION=1.12.1
ARG QEMU_VERSION=8.2.2

ARG UID=1001
ARG GID=1001

# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

# Install packages
RUN apt-get clean
RUN apt-get update
RUN apt-get upgrade -y

# software-properties for add-apt-repository
# locales for LANG support
# sudo to make life easier when running as build user
# vim.tiny so we have an editor
RUN apt-get install -y --no-install-recommends \
	software-properties-common locales locales-all sudo vim.tiny

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
RUN apt-get install -y --no-install-recommends \
	gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
	python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 \
	xz-utils unzip patch libstdc++6 diffstat build-essential chrpath \
	socat cpio python python3 python3-pip python3-pexpect \
	python3-setuptools debianutils iputils-ping ca-certificates

# Install packages for creating SDK packages
RUN apt-get install -y --no-install-recommends makeself p7zip-full tree curl

# Install CMake
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh && \
	chmod +x cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh && \
	./cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh --skip-license --prefix=/usr/local && \
	rm cmake-${CMAKE_VERSION}-linux-${HOSTTYPE}.sh

# Install ninja
RUN NINJA_SUFFIX=$(case $HOSTTYPE in aarch64) echo "-aarch64";; esac) && \
	wget https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux${NINJA_SUFFIX}.zip && \
	unzip ninja-linux${NINJA_SUFFIX}.zip && \
	mv ninja /usr/local/bin && \
	rm ninja-linux${NINJA_SUFFIX}.zip

# Install python packages to allow upload to aws S3
RUN pip3 install awscli

# Install meson to allow building picolibc
RUN pip3 install meson

# Install MinGW-w64 toolchain
COPY mingw-build.sh /mingw-build.sh
RUN /mingw-build.sh && rm -f /mingw-build.sh

# Install QEMU
RUN wget https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz && \
	tar Jxf qemu-${QEMU_VERSION}.tar.xz && \
	pushd qemu-${QEMU_VERSION} && \
	./configure --target-list="aarch64-softmmu,arm-softmmu,riscv32-softmmu,riscv64-softmmu" && \
	make -j$(nproc) && \
	make install && \
	popd && \
	rm -rf qemu-${QEMU_VERSION} && \
	rm qemu-${QEMU_VERSION}.tar.xz

# Add build-agent user
RUN groupadd -g $GID -o build-agent && \
    useradd -u $UID -m -g build-agent build-agent --shell /bin/bash && \
    echo 'build-agent ALL = NOPASSWD: ALL' > /etc/sudoers.d/build-agent && \
    chmod 0440 /etc/sudoers.d/build-agent

# NOTE: Do not switch to a non-root user because this creates all sorts of
#       permission-related problems with the GitHub Actions runner.
# USER build-agent
