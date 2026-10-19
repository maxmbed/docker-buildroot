# Docker Buildroot

A Docker container to make Linux-base images with Buildroot

# Build docker image

```shell
docker build -t docker-buildroot .
```

# Introduction 

Launch docker-buildroot container using the run script. 

Inside the container, an entry point agnostic script fetches instruction for getting Buildroot configured and ready. All files configuration such as defconfig, scripts, overlay, packages, archives must be located somewhere in the mount point `./materials` so Buildroot can use them. (note: mount point auto created and bond by run container script).

The script uses command line input to perform dedicated command inside the container. For example login container shell or to make buildroot.

Upon successfull build, resulting arftefacts images, rootfs, sdk and other materials output are copied outside of the container on the host file system (`./materials`).

# Persistent build

Container uses volumes to keep persistent Buildroot build dir, ccache, dl directories and also the sdk archives.

Volume tree:

```
cache/
|-- ccache-image
|-- ccache-sdk
|-- dl
`-- sdk
```

# Usage

Below describes run container commands

## Enter shell container

Launch container and login. This is handy to manually interact with buildroot (e.g. enter menuconfig, test build & configuration, edit files ...).

```sh
./run-cotnainer.sh -s
```

Launch container and login into target build (output) directory

```sh
./run-container.sh -s -t qemu_x86_64_weston
```

## Building a target

A target is a platform, a board or a project defined in `./materials/target.yaml` file. It should have at least necessary defconfig file and optionnal parameters for Buildroot.

Multiple targets can be defined within a single `target.yaml`.

### Build of sdk

Build a target sdk

```sh
./run-container.sh -t <target-name> -b sdk
```

> Tip: use option `-k` to keep container active after build and login shell 

### Build of rootfs image 

Build a target image

```sh
./run-container.sh -t <target-name> -b image

```

# Loging

Build logs are provided in `./logs` but only copied afeter build success or error.

Use below command to show in real time the build log

```sh
# Show build log
docker exec -it docker-buildroot tail -f logs/buildroot_image.log

# Show build run-container script status
docker exec -it docker-buildroot tail -f logs/buildroot_image.status
```
