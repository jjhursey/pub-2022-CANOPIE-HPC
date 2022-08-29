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
RUN mkdir -p /root/staged /root/src

COPY src/NPB3.4.2.tar.gz \
     etc/make.def \
     etc/suite.def \
     /root/src/

# ------------------------------------------------------------
# Install NAS Parallel Benchmarks
# https://www.nas.nasa.gov/software/npb.html
# ------------------------------------------------------------
ARG NAS_INSTALL_PATH=/opt/hpc/local/nas
ENV NAS_INSTALL_PATH=$NAS_INSTALL_PATH

RUN cd /root/staged && \
    tar -zxf /root/src/NPB3.4.2.tar.gz && \
    cd NPB3.4.2/NPB3.4-MPI && \
    cp /root/src/make.def config/make.def && \
    cp /root/src/suite.def config/suite.def && \
    make lu CLASS=A && \
    make -j 20 suite && \
    mkdir -p ${NAS_INSTALL_PATH} && \
    cp -R bin ${NAS_INSTALL_PATH}/ && \
    chmod -R og+rX ${NAS_INSTALL_PATH}/ && \
    rm -rf /root/staged /root/src

# ------------------------------------------------------------
# 
# ------------------------------------------------------------
