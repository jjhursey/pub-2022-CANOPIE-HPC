# ------------------------------------------------------------
# Taken from this repo:
#  https://github.com/jjhursey/k8s-waitfor
# ------------------------------------------------------------

# ------------------------------------------------------------
# Base image: RHEL UBI 8
# ------------------------------------------------------------
ARG IMAGE_BASE_RHEL=registry.access.redhat.com/ubi8/ubi
FROM ${IMAGE_BASE_RHEL} as buildenv

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jhursey@us.ibm.com"

# ------------------------------------------------------------
# Install required packages
#   bind-utils : For DNS query (dig, host, nslookup)
# ------------------------------------------------------------
RUN yum -y update && \
    yum -y install \
    bind-utils wget && \
    yum clean all

# ------------------------------------------------------------
# Kubernetes support functionality
# kubectl     : kubectl binary
# kubexec.sh  : kubectl wrapper to use as the launch agent for mpirun
# k8s-wait-for-pods.sh : Script used to wait for Pods to become 'Ready'
# ------------------------------------------------------------
ARG _K8S_VERSION=v1.23.4
ARG _K8S_ARCH=amd64

ENV _K8S_VERSION=${_K8S_VERSION}
ENV _K8S_ARCH=${_K8S_ARCH}

# Download a version
#RUN mkdir -p /opt/k8s/bin /opt/k8s/src && \
#    cd /opt/k8s/bin && \
#    wget -q https://storage.googleapis.com/kubernetes-release/release/${_K8S_VERSION}/bin/linux/${_K8S_ARCH}/kubectl && \
#    chmod +x ./kubectl
# - or -
# Use the local copy
COPY src/kubectl /tmp
RUN mkdir -p /opt/k8s/bin /opt/k8s/src && \
    cd /opt/k8s/bin && \
    mv /tmp/kubectl . && \
    chmod +x ./kubectl

COPY src/kubexec.sh \
     src/k8s-wait-for-pods.sh \
     /opt/k8s/bin/

# ------------------------------------------------------------
# Final stage
# ------------------------------------------------------------
ARG IMAGE_BASE_RHEL=registry.access.redhat.com/ubi8/ubi
FROM ${IMAGE_BASE_RHEL}

LABEL maintainer="jhursey@us.ibm.com"

# Install required packages
RUN yum -y update && \
    yum -y install \
    bind-utils && \
    yum clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# Kubernetes support functionality
ARG _K8S_VERSION=v1.23.4
ENV _K8S_VERSION=${_K8S_VERSION}
LABEL k8s.version=${_K8S_VERSION}

COPY --from=buildenv /opt/k8s/bin /opt/k8s/bin

CMD ["sh", "-c", "echo \"Kubernetes kubectl version: \" $_K8S_VERSION"]
