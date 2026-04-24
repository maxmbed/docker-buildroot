#!/bin/bash

workdir=/buildroot-home

mkdir -p materials

sudo docker run \
  --rm \
  --mount type=volume,source=buildroot-build-cache,destination=${workdir}/cache \
  --mount type=volume,source=buildroot-host,destination=${workdir}/target-builds \
  --mount type=bind,source="$(pwd)/materials",destination=${workdir}/materials \
  -it \
  -e "TERM=xterm-256color" \
  docker-buildroot \
  $@
