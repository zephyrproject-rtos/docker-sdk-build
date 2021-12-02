FROM ubuntu:18.04

ARG UID=1001
ARG GID=1001

# Make bash the default shell
ENV SHELL /bin/bash

# Install packages
RUN apt-get clean
RUN apt-get update

# software-properties for add-apt-repository
# locales for LANG support
# sudo to make life easier when running as build user
# vim.tiny so we have an editor
RUN apt-get install -y --no-install-recommends \
	software-properties-common locales sudo vim.tiny

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

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

# Install python3.8-dev for build w/GDB
RUN apt-get install -y --no-install-recommends python3.8-dev

# Install packages for creating SDK packages
RUN apt-get install -y --no-install-recommends makeself p7zip-full tree curl

# Install python packages to allow upload to aws S3
RUN pip3 install awscli

# Grab a new git
RUN add-apt-repository ppa:git-core/ppa -y && \
    apt-get update && \
    apt-get install -y git

# Add build-agent user
RUN groupadd -g $GID -o build-agent && \
    useradd -u $UID -m -g build-agent build-agent --shell /bin/bash && \
    echo 'build-agent ALL = NOPASSWD: ALL' > /etc/sudoers.d/build-agent && \
    chmod 0440 /etc/sudoers.d/build-agent

USER build-agent
