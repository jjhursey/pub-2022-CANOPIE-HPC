# ------------------------------------------------------------
# Base image: RHEL UBI 8
# ------------------------------------------------------------
ARG IMAGE_BASE=registry.access.redhat.com/ubi8/ubi
FROM ${IMAGE_BASE} as base

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jhursey@us.ibm.com"

# ------------------------------------------------------------
# Install required packages
# ------------------------------------------------------------
# RUN yum -y update && \
#     yum -y install dnf-plugins-core && \
#     yum -y install \
#         && \
#     yum clean all && \
#     rm -rf /var/cache /var/log/dnf* /var/log/yum.*
#     mkdir -p /root/staged /root/src


# ------------------------------------------------------------
# Install Open MPI without the runtime and external 3rd party libs
# ------------------------------------------------------------
ARG OMPI_INSTALL_PATH=/opt/hpc/local/openmpi
ENV OMPI_INSTALL_PATH=$OMPI_INSTALL_PATH

RUN mkdir -p /root/staged && \
    cd /root/staged && \
    git clone --depth 1 -b pub-2022-CANOPIE-HPC --recursive https://github.com/jjhursey/ompi.git ompi && \
    cd ompi && \
    ./autogen.pl --no-3rdparty libevent,hwloc,openpmix,prrte --no-oshmem && \
    ./configure --prefix=${OMPI_INSTALL_PATH} \
        --without-prrte \
        --with-pmix=${PMIX_INSTALL_PATH} \
        --with-hwloc=${HWLOC_INSTALL_PATH} \
        --with-libevent=${LIBEVENT_INSTALL_PATH} \
        --disable-man-pages \
        --disable-oshmem \
        --enable-debug && \
    make -j 20 > /dev/null && \
    make -j 20 install > /dev/null && \
    cd / && rm -rf /root/staged

ENV PATH="$OMPI_INSTALL_PATH/bin:${PATH}"
ENV LD_LIBRARY_PATH="$OMPI_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"


# ------------------------------------------------------------
# Copy in an MPI test program
# ------------------------------------------------------------
RUN mkdir -p /opt/hpc/examples/bin && chmod -R og+rwX /opt/hpc/examples
COPY tests /opt/hpc/examples
RUN cd /opt/hpc/examples/src && make && make install


# ------------------------------------------------------------
# Adjust the default environment
# ------------------------------------------------------------
USER root

RUN echo "export MPI_ROOT=$OMPI_INSTALL_PATH" >> /etc/bashrc && \
    echo "export PATH=$OMPI_INSTALL_PATH/bin:\$PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=$OMPI_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc


# ------------------------------------------------------------
# Display the Open MPI version
# ------------------------------------------------------------
CMD ["/opt/hpc/examples/bin/display_version"]
