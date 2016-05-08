FROM ubuntu:16.04
MAINTAINER Fabian Stäber, fabian@fstab.de

ENV LAST_UPDATE=2016-05-08

#---------------------------------------------------
# standard ubuntu set-up
#---------------------------------------------------

RUN apt-get update && \
    apt-get upgrade -y

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set the timezone
RUN echo "Europe/Berlin" | tee /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

#---------------------------------------------------
# go development
#---------------------------------------------------

RUN apt-get install -y \
    golang \
    git \
    wget \
    vim

WORKDIR /root
RUN mkdir go
ENV GOPATH /root/go
RUN echo 'GOPATH=$HOME/go' >> /root/.bashrc
RUN echo 'PATH=$GOPATH/bin:$PATH' >> /root/.bashrc

#---------------------------------------------------
# Install Oniguruma Library for Linux 64 Bit
#---------------------------------------------------

RUN apt-get install -y \
    build-essential \
    libonig-dev

#---------------------------------------------------
# Install Oniguruma Library for Windows 64 Bit
#---------------------------------------------------

RUN apt-get install -y \
    automake \
    automake1.11 \
    gcc-mingw-w64-x86-64 \
    libtool

# Cross-compile Oniguruma for mingw in /tmp

WORKDIR /tmp
RUN apt-get source libonig-dev
WORKDIR /tmp/libonig-5.9.6
RUN CC=x86_64-w64-mingw32-gcc ./configure --host x86_64-w64-mingw32 --prefix=/usr/x86_64-w64-mingw32
RUN CC=x86_64-w64-mingw32-gcc make || true
RUN mv '$(encdir)/.deps' enc
RUN CC=x86_64-w64-mingw32-gcc make
RUN CC=x86_64-w64-mingw32-gcc make install

WORKDIR /root
RUN rm -r /tmp/*

#---------------------------------------------------
# Create compile scripts
#---------------------------------------------------

# compile-win64.sh

RUN echo '#!/bin/bash' >> /root/compile-win64.sh
RUN echo '' >> /root/compile-win64.sh
RUN echo 'set -e' >> /root/compile-win64.sh
RUN echo '' >> /root/compile-win64.sh
RUN echo 'if [[ "$1" == "-o" ]] && [[ ! -z "$2" ]]' >> /root/compile-win64.sh
RUN echo 'then' >> /root/compile-win64.sh
RUN echo '    cd /root/go/src/github.com/fstab/grok_exporter' >> /root/compile-win64.sh
RUN echo '    CC=x86_64-w64-mingw32-gcc GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -v -o $2 .' >> /root/compile-win64.sh
RUN echo 'else' >> /root/compile-win64.sh
RUN echo '    echo "Usage: $(basename "$0") -o <file>" >&2' >> /root/compile-win64.sh
RUN echo '    exit 1' >> /root/compile-win64.sh
RUN echo 'fi' >> /root/compile-win64.sh

RUN chmod 755 /root/compile-win64.sh

ENTRYPOINT /bin/bash

ENTRYPOINT bash -c 'if [ -d "/root/go/src/github.com/fstab/grok_exporter" ] ; then \
    echo "Type \"ls\" to see the available compile scripts." && /bin/bash ; else  \
    echo "Did not find grok_exporter sources. Please run this container with \"-v \$GOPATH:/root/go\" and make sure the sources for \"github.com/fstab/grok_exporter\" are available in \"\$GOPATH\"." >&2 ; fi '