#!/bin/bash

VERSION=1.0.0
REVISION=1

docker run -v $(pwd):/src jrecord/fpm \
  -s dir \
  -t deb \
  -p "sysinfo-${VERSION}-${REVISION}.deb" \
  --name sysinfo \
  --license gpl2 \
  --version $VERSION \
  --architecture all \
  --depends bash \
  --description "Display a brief summary of system hardware, operating system, and networking for a host" \
  --url https://github.com/jedrecord/sysinfo \
  --maintainer "Jed Record <jed.record@gmail.com>" \
  sysinfo=/usr/bin/sysinfo \
  sysinfo.1=/usr/share/man/man1/sysinfo.1
