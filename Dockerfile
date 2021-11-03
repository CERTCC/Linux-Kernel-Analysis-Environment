###
# Setup build dependencies
###
ARG VERSION=latest 
FROM ubuntu:${VERSION} as build_dependencies

ENV DEBIAN_FRONTEND noninteractive
ENV LC_CTYPE C.UTF-8
# Enable deb-srcs
RUN sed -i '/^#\sdeb-src /s/^#//' "/etc/apt/sources.list"

# build kernel dependencies
RUN apt update && apt-get build-dep -y linux

# Install additional packages
RUN apt update && apt install -y \
                    git \
                    build-essential \
                    libncurses-dev \
                    flex \
                    bison \
                    openssl \
                    libssl-dev \
                    dkms \
                    libelf-dev \
                    libudev-dev \
                    libpci-dev \
                    libiberty-dev \
                    autoconf \
                    wget \
                    qemu-kvm \
                    qemu-system-x86 \
                    bridge-utils \
                    gcc g++


ENV KERNEL /kernel
RUN git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git $KERNEL


###
# Get the qemu vm image setup
###
FROM build_dependencies as env_setup

# additional packages and tools
RUN apt update && apt install -y iproute2 tmux gdb vim debootstrap sudo

ARG VERSION
RUN if [ "${VERSION}" = "18.04" ]; then \
    apt update && apt install -y gcc-4.8 gcc-5 gcc-6 gcc-7 gcc-8; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 4; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 5; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 6; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8; \
fi


RUN if [ "${VERSION}" = "20.04" ]; then \
    apt update && apt install -y gcc-7 gcc-8 gcc-9 gcc-10; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9; \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10; \
fi

# copy the qemu rootfs image
ARG RELEASE=buster
ENV RELEASE $RELEASE

ENV IMAGE /image
RUN mkdir /image
COPY images/create_image.sh $IMAGE

# copy scripts and give them execute privs
ENV VMSCRIPTS /analysis_scripts
WORKDIR /analysis_scripts
COPY analysis_scripts/* ./
RUN chmod +x ./*

# copy kernel option fragments
ENV KCONF_FRAGS /kernel_options
WORKDIR /kernel_options
COPY kernel_options/* ./

# configure build scripts gdb
ENV PATH $PATH:$VMSCRIPTS
WORKDIR /root
COPY .tmux.conf .
RUN wget -q -O- https://github.com/hugsy/gef/raw/master/scripts/gef.sh | sh
RUN echo "add-auto-load-safe-path /" >> .gdbinit
