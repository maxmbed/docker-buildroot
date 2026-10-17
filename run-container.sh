#!/bin/bash

workdir=/buildroot-home

mkdir -p materials

docker run \
  --rm \
  --privileged \
  -v /lib/modules:/lib/modules \
  --mount type=volume,source=buildroot-build-cache,destination=${workdir}/cache \
  --mount type=volume,source=buildroot-host,destination=${workdir}/target-builds \
  --mount type=bind,source="$(pwd)/materials",destination=${workdir}/materials \
  -p 127.0.0.1:5900:5900 \
  -it \
  -e "TERM=xterm-256color" \
  docker-buildroot \
  $@
