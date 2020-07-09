FROM ubuntu:18.04

WORKDIR /sdk-build

COPY setup.sh .

RUN ./setup.sh && \
 useradd -m buildkite-agent --shell /bin/bash --uid 2000 && \
 echo 'buildkite-agent ALL = NOPASSWD: ALL' > /etc/sudoers.d/buildkite-agent && \
 chmod 0440 /etc/sudoers.d/buildkite-agent

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
