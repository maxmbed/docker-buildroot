# Docker Buildroot

Docker Buildroot is a container to make Linux-base images using Buildroot

# Introduction 

Launch docker-buildroot container using the container run-script. 

Within the container, an agnostic entry-point script is used for getting Buildroot configured and ready to make. All files configuration such as defconfig, scripts, overlay, packages, archives must be located somewhere in the mount point `./materials` directory so Buildroot can use them inside the container. (note: mount point auto created and bond by run container script).

The container run-script uses command line option to perform commands inside the container such as login container shell or to make buildroot.

Upon successfull build, resulting arftefacts images, rootfs, sdk and other materials output are copied outside of the container on the host file system in `./materials` directory.

# Persistent build

Docker Buildroot provides volumes for keeping persistent build-dir, ccache, dl directories and sdk archives safe bewteen container sessions.

```sh
# Volume tree
cache/
|-- ccache-image
|-- ccache-sdk
|-- dl
`-- sdk
```

# Build docker image

```shell
docker build -t docker-buildroot .
```

# Usage

Below is describing container run script commands

## Enter container

Launch container and login into shell. This is handy for manually interacting with buildroot (e.g. get menuconfig, test build, configure, edit files, ...).

```sh
./run-cotnainer.sh -s
```

To straight login into target build-dir directory

```sh
./run-container.sh -s -t qemu_x86_64_weston
```

## Building a target

A target is a platform, a board or a project defined in file `./materials/target.yaml`. It should have at least the defconfig but can alos have optionnal parameters for Buildroot.

Multiple targets can be defined within `target.yaml`.

### Build sdk target

```sh
./run-container.sh -t <target-name> -b sdk
```

### Build image target 

```sh
./run-container.sh -t <target-name> -b image

```

> Tip: use option `-k` to keep container shell active after build  

# Logs

Build logs are provided in directory `./logs` but they can only be copied after build success or error.

So to watch the build log in real timen, execute docker in interactive mode to get log 

```sh
# Watch build log
docker exec -it docker-buildroot tail -f logs/buildroot_image.log

# Watch run-container script status
docker exec -it docker-buildroot tail -f logs/buildroot_image.status
```

