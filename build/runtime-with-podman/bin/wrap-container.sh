#!/bin/bash

# Podman specific
which podman 2>/dev/null 1>/dev/null
if [ $? -eq 0 ] ; then
    CONTAINER_RUNTIME=podman
else
    CONTAINER_RUNTIME=docker
fi

# --pmixmca psec none
#  Needed because the user outside running "prterun" is different than the user inside the container.
#
# Single node
# prterun --personality ompi --pmixmca psec none --np 2 ./wrap-docker.sh /opt/hpc/examples/bin/init_finalize
#
# Multiple nodes
# prterun --personality ompi  --host f5n18:2,f5n17:2 --pmixmca psec none --np 4 ./wrap-docker.sh /opt/hpc/examples/bin/init_finalize

#
# Pick up the handshake environment variables and inject them into the containers
#
if [[ $CONTAINER_RUNTIME == "docker" ]] ; then
    _TMP_ENV_FILE=`mktemp /tmp/docker-env-${PMIX_RANK}-XXXX.txt`
    env | sort | grep '^PMIX' > ${_TMP_ENV_FILE}
    env | sort | grep '^OMPI' >> ${_TMP_ENV_FILE}
fi

# 
# Required Docker flags to share between containers and with the PMIx Server
#
_REQUIRED_ARGS=""

# --network host
#  Needed because the PMIx server and client talk over a TCP socket
#  PMIX_SERVER_URI41=prterun-f5n18-3903919@0.0;tcp4://10.20.160.172:57983
_REQUIRED_ARGS+=" --network host"

# --uts host
#  For MPI to setup the shared memory segment (uses hostnames)
#  Alternative: --hostname $PMIX_HOSTNAME
_REQUIRED_ARGS+=" --uts host"

# --pid host
# --ipc host
#  Needed so that the PMIx server can signal the client, and for
#  the MPI jobs to wireup shared memory
_REQUIRED_ARGS+=" --pid host"
_REQUIRED_ARGS+=" --ipc host"

# --cgroups=no-conmon
#   Needed for Kubernetes environment.
#   Disable new cgroup only for conmon process.
_REQUIRED_ARGS+=" --cgroups=no-conmon"

# -v /dev/shm:/dev/shm
#  For MPI to setup a shared memory segment
#  Otherwise: -v $TMPDIR:$TMPDIR
_REQUIRED_ARGS+=" -v /dev/shm:/dev/shm"

# --cap-add=sys_ptrace
#   For MPI CMA Shared Memory operations
_REQUIRED_ARGS+=" --cap-add=sys_ptrace"


# PMIX/OMPI Environment variables
if [[ $CONTAINER_RUNTIME == "docker" ]] ; then
    _REQUIRED_ARGS+=" --env-file=${_TMP_ENV_FILE}"
else
    _REQUIRED_ARGS+=" --env-host"
fi

#
# Execute the container in the proper environment
#
MPI_IMAGE=${MPI_IMAGE:-k8s-mpi}
if [[ "x" != "x$WRAP_DEBUG" ]] ; then
    echo $CONTAINER_RUNTIME run ${_REQUIRED_ARGS} --rm ${CONTAINER_ARGS} $MPI_IMAGE $@
fi
$CONTAINER_RUNTIME run ${_REQUIRED_ARGS} --rm ${CONTAINER_ARGS} $MPI_IMAGE $@
RTN=$?

#
# Cleanup
#
if [[ $CONTAINER_RUNTIME == "docker" ]] ; then
    rm ${_TMP_ENV_FILE}
fi

exit $RTN
