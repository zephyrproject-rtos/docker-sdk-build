FROM ubuntu:18.04

ARG UID=1001
ARG GID=1001

# Run setup script
WORKDIR /sdk-build
COPY setup.sh .
RUN ./setup.sh

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add build-agent user
RUN groupadd -g $GID -o build-agent

RUN useradd -u $UID -m -g build-agent build-agent --shell /bin/bash && \
 echo 'build-agent ALL = NOPASSWD: ALL' > /etc/sudoers.d/build-agent && \
 chmod 0440 /etc/sudoers.d/build-agent

USER build-agent
