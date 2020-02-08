FROM ubuntu:18.04

WORKDIR /sdk-build

COPY setup.sh .

RUN ./setup.sh && \
 useradd -m build --shell /bin/bash && \
 echo 'build ALL = NOPASSWD: ALL' > /etc/sudoers.d/build && \
 chmod 0440 /etc/sudoers.d/build

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
