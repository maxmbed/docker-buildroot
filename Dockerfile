# Docker Buildroot

FROM debian:12
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
# Interface dependecies \
        libncurses5 \
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
        dblatex


# /!\ Workaround /!\ 
# Hack 'tar' to add options since some packages expect ownership (uid,gid) changes (e.g. google protobuf). 
# https://github.com/aws/aws-lambda-python-runtime-interface-client/issues/37
RUN mkdir -p /opt/bin && mv /bin/tar /opt/bin/
COPY tar.sh /bin/tar
RUN chmod 755 /bin/tar

