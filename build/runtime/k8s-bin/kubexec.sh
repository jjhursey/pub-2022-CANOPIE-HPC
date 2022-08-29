#!/bin/sh

# Name of the POD to exec into
POD_NAME=$1
if [ "x" == "x$POD_NAME" ] ; then
    echo "Error: Supply the pod name on the command line before any other arguments."
    exit 1
fi

shift
if [ "x" == "x$NAMESPACE" ] ; then
    /opt/k8s/bin/kubectl exec ${POD_NAME} -- /bin/sh -c "$*"
else
    /opt/k8s/bin/kubectl exec --namespace ${NAMESPACE} ${POD_NAME} -- /bin/sh -c "$*"
fi
