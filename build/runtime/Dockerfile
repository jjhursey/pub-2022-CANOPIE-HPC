# ------------------------------------------------------------
# Base image: RHEL UBI 8
# ------------------------------------------------------------
ARG IMAGE_BASE=registry.access.redhat.com/ubi8/ubi
FROM ${IMAGE_BASE}

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jhursey@us.ibm.com"


# ------------------------------------------------------------
# Install required packages
# ------------------------------------------------------------
RUN yum -y update && \
    yum -y install dnf-plugins-core && \
    yum -y install \
        openssh-server openssh-clients \
        && \
    yum clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.* && \
    mkdir -p /root/staged /root/src


# ------------------------------------------------------------
# Install PRRTE
# ------------------------------------------------------------
ARG PRRTE_INSTALL_PATH=/opt/hpc/local/prrte
ENV PRRTE_INSTALL_PATH=$PRRTE_INSTALL_PATH
RUN cd /root/staged && \
    git clone --depth 1 -b pub-2022-CANOPIE-HPC https://github.com/jjhursey/prrte.git prrte && \
    cd prrte && \
    ./autogen.pl && \
        ./configure --prefix=${PRRTE_INSTALL_PATH} \
        --with-pmix=${PMIX_INSTALL_PATH} \
        --with-hwloc=${HWLOC_INSTALL_PATH} \
        --with-libevent=${LIBEVENT_INSTALL_PATH} && \
    make -j 20 > /dev/null && \
    make -j 20 install > /dev/null && \
    cd / && rm -rf /root/staged/prrte*
ENV PATH="$PRRTE_INSTALL_PATH/bin:${PATH}"
ENV LD_LIBRARY_PATH="$PRRTE_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"
# cd / && rm -rf /root/staged/prrte


# ------------------------------------------------------------
# Add the sample launcher for the plm/k8sgo
# Run with:
#  prterun --map-by ppr:2:node --mca plm_k8sgo_launch_script /opt/hpc/bin/basic_launcher  hostname
# or set the following envar before calling 'prte'
#  PRTE_MCA_plm_k8sgo_launch_script=/opt/hpc/bin/basic_launcher
# ------------------------------------------------------------
RUN mkdir -p /opt/hpc/bin
COPY src /opt/hpc/bin
RUN cd /opt/hpc/bin && make


# ------------------------------------------------------------
# Copy in the Kubernetes setup
# ------------------------------------------------------------
COPY k8s-bin/kubectl /opt/k8s/bin
COPY k8s-bin/kubexec.sh /opt/k8s/bin
RUN cd /opt/k8s/bin && chmod +x ./kubectl


# ------------------------------------------------------------
# Fixup the ssh login
# ------------------------------------------------------------
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key  -N "" && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key  -N "" && \
    echo "        LogLevel ERROR" >> /etc/ssh/ssh_config && \
    echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    echo "        PubkeyAuthentication yes" >> /etc/ssh/ssh_config && \
    echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo -n > /var/log/btmp && \
    echo -n > /var/log/wtmp && \
    echo -n > /var/log/secure && \
    echo -n > /var/log/lastlog && \
    sed -i 's/^session     required      pam_limits.so/session     optional      pam_limits.so/' /etc/pam.d/password-auth


# ------------------------------------------------------------
# Update a user account
# ------------------------------------------------------------
USER mpiuser
WORKDIR /home/mpiuser
COPY --chown=mpiuser sshd_config .sshd_config
RUN ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa && chmod og+rX . && \
    cd /home/mpiuser/.ssh && \
    cat id_rsa.pub > authorized_keys && chmod 644 authorized_keys

USER root
WORKDIR /


# ------------------------------------------------------------
# Update the default environment
# ------------------------------------------------------------
USER root

RUN echo "export PATH=$PRRTE_INSTALL_PATH/bin:\$PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=$PRRTE_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc
