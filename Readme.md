# Docker Buildroot

A Docker container to make Linux-base images with Buildroot

# Build docker image

```shell
docker build -t docker-buildroot .
```

# Introduction 

Start docker-buildroot container using the run script. 

Few input may be parsed to perform dedicated action inside the container for example entering the shell or for starting buildroot.

The container entry point is an agnostic script which read yaml parameters need for getting Buildroot ready to go. Input configuration such as defconfig, scripts, packages, archives should be placed inside the mount point `./materials` (auto create and mounted by run script).

Upon successfull build, resulting arftefacts images, rootfs, sdk and other materials output are copied within `./materials`.

Container uses volume to keep persistent ccache, host and downloads directories.

# Usage

Below describes few container entry point commands.

## Enter shell container

Launch container and login. This is handy to manually interact with buildroot (e.g. enter menuconfig, try build, edit files ...).

```sh
./run-cotnainer.sh -s
```

## Building target

Run the build of a target.

A target is a platform, board or project that is defined under `./materials/target.yaml`. It should have at least defconfig file but it may contain other optionnal parameters need for Buildroot as well.

Multiple targets can be defined in single `target.yaml`. Each target can be used to define sdk, images and more.

## Persistent volume

Container creates/uses volume to keep buildroot ccache, host and download directories persistent between run of containers

Volume tree:

```
cache/
|-- ccache-image
|-- ccache-sdk
|-- dl
`-- sdk*
```

> *a copy of sdk is kept in volume to build image 

### Sdk

Build a target sdk

```sh
./run-container.sh -t <target-name> -b sdk
```

### Image

Build a target image

```sh
./run-container.sh -t <target-name> -b image

```
