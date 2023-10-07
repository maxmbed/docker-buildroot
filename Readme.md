# Docker Buildroot
A Docker container to work and produce Buildroot images through a bind mounts working directory.

# Build images

```shell
docker run -t docker-br .
```

# Usage

Get Buildroot if not done already

```shell
git clone https://github.com/buildroot/buildroot.git
cd buildroot
```

Launch container

```shell
docker run -it --mount type=bind,source="$(pwd)",destination=/buildroot-dev docker-br
```

Then your Buildroot work directory should be bind in `/buildroot-dev`.
