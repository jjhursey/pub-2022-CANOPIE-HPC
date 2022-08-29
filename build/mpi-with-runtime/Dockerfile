# ------------------------------------------------------------
# Base image: Runtime
# ------------------------------------------------------------
ARG IMAGE_BASE=k8s-runtime:latest
ARG IMAGE_BASE_MPI=k8s-mpi:latest
FROM ${IMAGE_BASE_MPI} as mpibase
FROM ${IMAGE_BASE} as base

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jhursey@us.ibm.com"


# ------------------------------------------------------------
# Copy Open MPI from the IMAGE_BASE_MPI container
# ------------------------------------------------------------
ARG OMPI_INSTALL_PATH=/opt/hpc/local/openmpi
ENV OMPI_INSTALL_PATH=$OMPI_INSTALL_PATH

ENV MPI_ROOT="$OMPI_INSTALL_PATH"
ENV PATH="$OMPI_INSTALL_PATH/bin:${PATH}"
ENV LD_LIBRARY_PATH="$OMPI_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"

COPY --from=mpibase ${OMPI_INSTALL_PATH} ${OMPI_INSTALL_PATH}


# ------------------------------------------------------------
# Copy in an MPI test program
# ------------------------------------------------------------
COPY --from=mpibase /opt/hpc/examples /opt/hpc/examples


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
