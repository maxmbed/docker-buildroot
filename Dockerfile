# Docker Buildroot

FROM debian:13
RUN apt-get update -y

# Buildroot mandatory package:
# https://buildroot.org/downloads/manual/manual.html#requirement-mandatory
RUN apt-get install -y \
        which \
        sed \ 
        make \
        binutils \
        diffutils \
        gcc \
        g++ \
        bash \
        patch \
        gzip \
        bzip2 \
        perl \
        tar \
        cpio \
        unzip \
        rsync \
        file \
        bc \
        findutils \
        wget
     

# Buildroot optional package:
# https://buildroot.org/downloads/manual/manual.html#requirement-optional
RUN apt-get install -y \
        python3 \
# User Interface dependecies \
        libncurses6 libncurses-dev \
#       qt5 \
#       glib2 gtk2 glade2 \
# Source fetching tools \
        git \
#       bazaar \
#       cvs \
#       subversion \
#       mercurial \
        rsync \
        openssh-client \
        javacc \
        asciidoc \
        w3m \
        dblatex \
# User utility \
        vim \
        yq \
        nnn

WORKDIR /buildroot-home
# Below volumes are created to keeps Buildroot ccache, download and host directory persistent
VOLUME /buildroot-home/cache
VOLUME /buildroot-home/target-builds

RUN mkdir logs
# Get Buildroot, jaihouse hypervisor and linux kernel for jailhouse
RUN git clone --depth 1 -b 2025.02 https://gitlab.com/buildroot.org/buildroot.git
COPY ./docker-entrypoint.sh ./
ENTRYPOINT [ "/bin/bash", "./docker-entrypoint.sh" ]
CMD ["-s"]

