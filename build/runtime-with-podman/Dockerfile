# ------------------------------------------------------------
# Base image: Runtime
# ------------------------------------------------------------
ARG IMAGE_BASE_RUNTIME=k8s-runtime:latest
FROM ${IMAGE_BASE_RUNTIME}

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jhursey@us.ibm.com"

# ------------------------------------------------------------
# Install required packages
# Taken from podman-in-podman with some customization
#  https://www.redhat.com/sysadmin/podman-inside-container
# ------------------------------------------------------------
RUN dnf -y update; \
    yum -y reinstall shadow-utils; \
    yum -y install crun podman fuse-overlayfs --exclude container-selinux; \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# Add rootless for the 'mpiuser'
RUN echo mpiuser:10000:5000 > /etc/subuid; \
    echo mpiuser:10000:5000 > /etc/subgid;

# Rootfull container storage
#VOLUME /var/lib/containers
# Rootless container storage
#VOLUME /home/mpiuser/.local/share/containers

# https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf
COPY etc/containers.conf /etc/containers/containers.conf
# https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf
ADD etc/podman-containers.conf /home/podman/.config/containers/containers.conf
# Insecure registry config
COPY etc/registries.conf /etc/containers/registries.conf

# Fix permissions
RUN chown mpiuser:mpiuser -R /home/mpiuser

# Setup fuse-overlayfs
RUN chmod 644 /etc/containers/containers.conf; \
    sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; \
    touch /var/lib/shared/overlay-images/images.lock; \
    touch /var/lib/shared/overlay-layers/layers.lock; \
    touch /var/lib/shared/vfs-images/images.lock; \
    touch /var/lib/shared/vfs-layers/layers.lock

# Clear
ENV _CONTAINERS_USERNS_CONFIGURED=""

# ------------------------------------------------------------
# Wrapper for container launches via prterun
# ------------------------------------------------------------
ARG MPI_IMAGE=k8s-mpi:latest
ENV MPI_IMAGE=${MPI_IMAGE}
ENV CONTAINER_ARGS="--user 998:995"

RUN mkdir -p /opt/hpc/local/bin
COPY bin/wrap-container.sh /opt/hpc/local/bin/wrap-container.sh

#---------------------------------------
CMD ["podman --version"]
