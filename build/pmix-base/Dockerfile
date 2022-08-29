# ------------------------------------------------------------
# Base image: RHEL UBI 8
# ------------------------------------------------------------
ARG IMAGE_BASE_RHEL=registry.access.redhat.com/ubi8/ubi
FROM ${IMAGE_BASE_RHEL}

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jhursey@us.ibm.com"

ARG _BUILD_FLEX_VERSION=2.6.4
ARG _BUILD_HWLOC_VERSION=2.7.1
ARG _BUILD_LIBEVENT_VERSION=2.1.12

LABEL com.ibm.flex.version=${_BUILD_FLEX_VERSION}
LABEL com.ibm.hwloc.version=${_BUILD_HWLOC_VERSION}
LABEL com.ibm.libevent.version=${_BUILD_LIBEVENT_VERSION}

# ------------------------------------------------------------
# Install required packages
# flex, bison, strace, numactl-devel
# EPEL: rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
# ------------------------------------------------------------
RUN yum -y update && \
    yum -y install dnf-plugins-core && \
    yum -y install \
        gcc gcc-gfortran gcc-c++ gdb \
        bzip2 gzip \
        binutils less wget which sudo \
        perl perl-Data-Dumper \
        m4 autoconf automake libtool \
        libnl3 gtk2 atk cairo tcl tk pciutils lsof ethtool bc file \
        libxml2-devel \
        iproute net-tools \
        make git patch diffutils hostname \
        psmisc \
        ncurses ncurses-compat-libs \
        python3 man procps \
        bind-utils && \
    yum clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.* && \
    mkdir -p /root/staged /root/src


# ------------------------------------------------------------
# Copy in Deps to install
# ------------------------------------------------------------
COPY deps/hwloc-${_BUILD_HWLOC_VERSION}.tar.gz \
     deps/libevent-${_BUILD_LIBEVENT_VERSION}-stable.tar.gz \
     deps/flex-${_BUILD_FLEX_VERSION}.tar.gz \
     /root/src/


# ------------------------------------------------------------
# Copy in a 'pause' program from Kubernetes
# ------------------------------------------------------------
RUN mkdir -p /opt/k8s/bin /opt/k8s/src
COPY src/pause.c /opt/k8s/src
RUN cd /opt/k8s && gcc src/pause.c -o bin/pause


# ------------------------------------------------------------
# Install flex
# ------------------------------------------------------------
ARG FLEX_INSTALL_PATH=/opt/hpc/local/flex
ENV FLEX_INSTALL_PATH=$FLEX_INSTALL_PATH

RUN cd /root/staged && \
    tar -zxf /root/src/flex-${_BUILD_FLEX_VERSION}.tar.gz && \
    cd flex-${_BUILD_FLEX_VERSION} && \
    ./configure --prefix=${FLEX_INSTALL_PATH} && \
    make && \
    make install && \
    cd / && rm -rf /root/staged/flex*
ENV PATH="$FLEX_INSTALL_PATH/bin:${PATH}"
ENV LD_LIBRARY_PATH="$FLEX_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"


# ------------------------------------------------------------
# Install hwloc
# ------------------------------------------------------------
ARG HWLOC_INSTALL_PATH=/opt/hpc/local/hwloc
ENV HWLOC_INSTALL_PATH=$HWLOC_INSTALL_PATH

RUN cd /root/staged/ && \
    tar -zxf /root/src/hwloc-${_BUILD_HWLOC_VERSION}.tar.gz && \
    cd hwloc-${_BUILD_HWLOC_VERSION} && \
    ./configure --prefix=${HWLOC_INSTALL_PATH} --disable-cuda --disable-nvml --with-cuda=no > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd / && rm -rf /root/staged/hwloc*
ENV PATH="$HWLOC_INSTALL_PATH/bin:${PATH}"
ENV LD_LIBRARY_PATH="$HWLOC_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"


# ------------------------------------------------------------
# Install libevent
# ------------------------------------------------------------
ARG LIBEVENT_INSTALL_PATH=/opt/hpc/local/libevent
ENV LIBEVENT_INSTALL_PATH=$LIBEVENT_INSTALL_PATH

RUN cd /root/staged/ && \
    tar -zxf /root/src/libevent-${_BUILD_LIBEVENT_VERSION}-stable.tar.gz && \
    cd libevent-* && \
    ./configure --prefix=${LIBEVENT_INSTALL_PATH} --disable-openssl \
    --disable-openssl --enable-thread-support \
    --disable-gcc-warnings --disable-libevent-regress \
    > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd / && rm -rf /root/staged/libevent*
ENV LD_LIBRARY_PATH="$LIBEVENT_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"


# ------------------------------------------------------------
# Install OpenPMIx
# ------------------------------------------------------------
ARG PMIX_INSTALL_PATH=/opt/hpc/local/openpmix
ENV PMIX_INSTALL_PATH=$PMIX_INSTALL_PATH

RUN cd /root/staged && \
    git clone --depth 1 -b pub-2022-CANOPIE-HPC https://github.com/jjhursey/openpmix.git openpmix && \
    cd openpmix && \
    ./autogen.pl && \
    ./configure --prefix=${PMIX_INSTALL_PATH} \
        --with-hwloc=${HWLOC_INSTALL_PATH} \
        --with-libevent=${LIBEVENT_INSTALL_PATH} \
        --enable-debug && \
    make -j 20 > /dev/null && \
    make -j 20 install > /dev/null && \
    cd / && rm -rf /root/staged/openpmix*
ENV PATH="$PATH/bin:${PATH}"
ENV LD_LIBRARY_PATH="$PMIX_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"
# cd / && rm -rf /root/staged/openpmix


# ------------------------------------------------------------
# Create a user account
# - Give sudo access while debugging
# ------------------------------------------------------------
RUN groupadd -r mpiuser && \
    useradd --no-log-init -r -m -b /home -g mpiuser mpiuser && \
    echo "mpiuser:mpiuser" | chpasswd && \
    echo "mpiuser ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/mpiuser && \
    chmod 0440 /etc/sudoers.d/mpiuser

USER mpiuser
WORKDIR /home/mpiuser

USER root
RUN echo rootytoottoot | passwd --stdin root
WORKDIR /


# ------------------------------------------------------------
# Adjust the default environment
# ------------------------------------------------------------
USER root

RUN echo "export LD_LIBRARY_PATH=$LIBEVENT_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export PATH=$FLEX_INSTALL_PATH/bin:\$PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=$FLEX_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export PATH=$HWLOC_INSTALL_PATH/bin:\$PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=$HWLOC_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export PATH=$PMIX_INSTALL_PATH/bin:\$PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=$PMIX_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export PATH=$PRRTE_INSTALL_PATH/bin:\$PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=$PRRTE_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc && \
    echo "export AUTOMAKE_JOBS=20" >> /etc/bashrc

ENV AUTOMAKE_JOBS=20
