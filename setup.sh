#!/bin/bash -e

apt-get clean
apt-get update

# software-properties for add-apt-repository
# locales for LANG support
# sudo to make life easier when running as build user
# vim.tiny so we have an editor
apt-get install -y --no-install-recommends software-properties-common \
	locales sudo vim.tiny

# The package sets are based on Yocto & crosstool-ng docs/references:
#
# Yocto:
# https://www.yoctoproject.org/docs/2.3.4/ref-manual/ref-manual.html#ubuntu-packages
#
# crosstool-ng:
# https://github.com/crosstool-ng/crosstool-ng/blob/master/testing/docker/ubuntu18.04/Dockerfile

apt-get install -y --no-install-recommends gcc g++ gperf bison flex texinfo \
	help2man make libncurses5-dev python3-dev autoconf automake libtool \
	libtool-bin gawk wget bzip2 xz-utils unzip patch libstdc++6 diffstat \
	gcc-multilib build-essential chrpath socat cpio python python3 \
	python3-pip python3-pexpect debianutils iputils-ping

# Grab a new git
add-apt-repository ppa:git-core/ppa -y
apt-get update
apt-get install git -y
