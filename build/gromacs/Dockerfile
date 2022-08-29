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
RUN yum -y update && \
    yum -y remove python36 && \
    yum -y install \
        cmake \
        python38 python38-devel \
        fftw fftw-libs fftw-devel \
        && \
    yum clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.* && \
    mkdir -p /root/staged /root/src

COPY deps/gromacs-2022.2.tar.gz \
     deps/benchMEM.zip \
     /root/src/

# ------------------------------------------------------------
# Install Gromacs
# https://manual.gromacs.org/current/install-guide/index.html
# Spack:
#   https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/gromacs/package.py
# ------------------------------------------------------------
ARG GROMACS_INSTALL_PATH=/opt/hpc/local/gromacs
ENV GROMACS_INSTALL_PATH=$GROMACS_INSTALL_PATH

RUN cd /root/staged && \
    mv /root/src/gromacs-2022.2.tar.gz . && \
    tar -zxf gromacs-2022.2.tar.gz && \
    cd gromacs-2022.2 && \
    mkdir build && cd build && \
    cmake .. \
      -DCMAKE_INSTALL_PREFIX=$GROMACS_INSTALL_PATH \
      -DGMX_BUILD_OWN_FFTW=OFF \
      -DGMX_MPI=on \
      -DGMX_HWLOC=ON -DHWLOC_INCLUDE_DIRS=$HWLOC_INSTALL_PATH/include/ \
      -DBUILD_TESTING=OFF && \
    make -j 20 && \
    make -j 20 install && \
    rm -rf /root/staged/gromacs*

RUN echo "source ${GROMACS_INSTALL_PATH}/bin/GMXRC" >> /etc/bashrc


# ------------------------------------------------------------
# Setup Gromacs example benchmark
# https://ftp.gromacs.org/pub/benchmarks/gmxbench-3.0.tar.gz
# -- these benchmarks do not work with the latest Gromacs
# ------------------------------------------------------------

# ------------------------------------------------------------
# Community Benchmark
# https://www.mpibpc.mpg.de/grubmueller/bench
# - benchMEM is the smallest (3.4 MB)
# ------------------------------------------------------------
RUN mkdir -p $GROMACS_INSTALL_PATH/examples/benchMEM && \
    cd $GROMACS_INSTALL_PATH/examples/benchMEM && \
    unzip /root/src/benchMEM.zip

RUN rm -rf /root/staged /root/src

# ------------------------------------------------------------
# Display the  version
# ------------------------------------------------------------
CMD ["gmx_mpi --version"]
