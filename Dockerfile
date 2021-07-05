FROM ubuntu:hirsute

ARG uid
ARG workspace

COPY build-cppcoro /var/tmp

RUN useradd --create-home --shell /bin/bash --uid $uid worker \
    && mkdir $workspace \
    && chown $uid $workspace \
    && apt-get update \
    && apt-get dist-upgrade --yes \
    && apt-get install --yes g++-11 cmake git \
    && /var/tmp/build-cppcoro

WORKDIR $workspace
