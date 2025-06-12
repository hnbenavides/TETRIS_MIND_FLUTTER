FROM debian:bookworm

RUN apt-get update && apt-get -y install git curl unzip

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /home/workspaces
WORKDIR /home/workspaces

ENV PUB_CACHE=/home/workspaces/.pub_cache
ENV PATH="/home/workspaces/flutter/bin:$PATH"

RUN git clone https://github.com/flutter/flutter && \
    /home/workspaces/flutter/bin/flutter config --enable-web
