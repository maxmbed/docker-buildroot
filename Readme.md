# Docker Buildroot

Docker Buildroot is a container for controling Buildroot with run-script to make
Linux rootfs images easy and portable.

## Usage introduction

Launch docker-buildroot container using the run-script.

Within the container, an agnostic entry-point script is executed for getting Buildroot
configured and ready to "make" things. Container uses mount point `./materials`
as passerel between host mahcine and container and to source configuration files
such as defconfig, scripts, overlay, packages and archives.

The container run-script provides command line option for loging container shell,
making buildroot, run menuconfig and so on.

Upon successfull build, rootfs image, kernel, sdk and any other output are copied
back to host mahcine.

Below show an example of materials directory

```sh
$ tree -L3
materials
├── board
│   └── qemu
│       └── x86_64_weston
├── configs
│   ├── image
│   │   └── qemu_x86_64_weston_defconfig
│   └── sdk
│       └── qemu_x86_64_defconfig
├── images
│   ├── bzImage
│   └── rootfs.ext2
├── logs
│   ├── qemu_x86_64_weston
│   │   ├── buildroot_image.log
│   │   └── buildroot_image.status
│   └── shell.log
└── target.yaml
```

## Persistent build

Docker Buildroot is using volumes for keeping persistent build-dir, ccache, dl
directories and sdk archives available between container sessions.

```sh
# Volume tree
cache/
|-- ccache-image
|-- ccache-sdk
|-- dl
`-- sdk
```

Target build is also a persistent volume and each build have a direcotry

```sh
# Target-buil treed
target-builds/
|-- qemu_x86_64_weston
    |-- build
    |-- host
    |-- images
    |-- staging
    `-- target
```

## Build docker image

```shell
docker build -t docker-buildroot .
```

## Run-script usage

### Enter container

Enter container and login into bash shell. This is handy for manually interacting
with container and buildroot (e.g. get menuconfig, test build, configure, edit
files, ...).

```sh
./run-cotnainer.sh -s
```

To shortcut login in target build directory

```sh
./run-container.sh -s -t qemu_x86_64_weston
```

## Building a target

A target is a project defined in file `./materials/target.yaml`.

A target can also be an existing defconfig in `buildroot/configs`.

Multiple targets can be defined within `target.yaml`.

E.g of target.yaml:

```yaml
qemu_x86_64_weston:
    sdk:
        defconfig: "materials/configs/sdk/qemu_x86_64_defconfig"
        toolchain_archive: "x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz"
    image:
        defconfig: "materials/configs/image/qemu_x86_64_weston_defconfig"
    nproc: 4

    run:
      - export PATH="/buildroot-home/target-builds/qemu_x86_64_weston/host/bin:${PATH}"
      - cd /buildroot-home/target-builds/qemu_x86_64_weston/images
      - qemu-system-x86_64 -M pc -enable-kvm -m 1024 -kernel bzImage -drive file=rootfs.ext2,format=raw,if=ide -append "root=/dev/sda rw console=ttyS0" -serial mon:stdio -net nic,model=virtio -net user -display none -vnc 0.0.0.0:0 -device VGA -device usb-ehci -device usb-kbd -device usb-tablet
```

### Build sdk target

```sh
./run-container.sh -t <target-name> -b sdk
```

### Build image target

```sh
./run-container.sh -t <target-name> -b image
```

### Build existing defconfig

```sh
./run-container.sh -t orangepi_zero2w_defconfig -b image
```

> Tip: use option `-k` to keep container shell active after build  

### Clean, distclean, menuconfig or any buildroot command

Any buildroot commands can be invoked

```sh
./run-container.sh -t <target-name> -b clean
./run-container.sh -t <target-name> -b distclean
./run-container.sh -t <target-name> -b menuconfig
```

## Logs

Build are logged inside the container in `./logs/<target-name>` and are
exported to host after build success or error in `./materials/logs/<target-name>`

For detatched container run in background, build log can be watched in real time

```sh
# Watch build log
docker exec -it docker-buildroot tail -f logs/<target-name>/buildroot_image.log

# Watch run-container script status
docker exec -it docker-buildroot tail -f logs/<target_name>/buildroot_image.status
```
