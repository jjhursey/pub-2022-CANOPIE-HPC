#!/bin/bash

#
# Wait for the compute 'nodes'/Pods to startup.
#
# Useful in an initContainers section of a Job to prevent the Job from starting
# before the Pods are all running.
#

###################################
# Argument processing
###################################
# (1) Number of servers to wait for
_TARGET_CNS=$1
# (2) Namespace
_NSPACE=$2
# (3) Pod selector to wait for
_SELECTOR=$3
# (4) Cluster domain to wait for
_TARGET_CLUSTER=$4
# (5) StatefulSet Prefix
_TARGET_PREFIX=$5
# (6) File in which to write the results
_TARGET_HOSTFILE=$6
# (6) File in which to write the results
_TARGET_HOSTFILE_IP=$7
# (7) Extra arguments for each line in the hostfile
if [ ! -z "$8" ] ; then
    _TARGET_HOSTFILE_ARGS=" "$8
fi

#
# Verify all command line arguments
#
if [ "x" == "x$_TARGET_CNS" ] ; then
    echo "Error: Supply the number of servers to wait for."
    exit 0
fi

if [ "x" == "x$_SELECTOR" ] ; then
    echo "Error: Supply the selector string to wait for Ready."
    exit 0
fi

if [ "x" == "x$_TARGET_CLUSTER" ] ; then
    echo "Error: Supply the target cluster name to wait for."
    exit 0
fi

echo "======================"
echo "Target Num Pods: ${_TARGET_CNS}"
echo "Namespace      : ${_NSPACE}"
echo "Pod Selector   : ${_SELECTOR}"
echo "Pod Domain     : ${_TARGET_CLUSTER}"
echo "Pod Prefix     : ${_TARGET_PREFIX}"
if [ "x" != "x$_TARGET_HOSTFILE" ] ; then
    echo "Hostfile       : ${_TARGET_HOSTFILE}"
fi
if [ "x" != "x$_TARGET_HOSTFILE_IP" ] ; then
    echo "Hostfile (IP)  : ${_TARGET_HOSTFILE_IP}"
fi
if [ "x" != "x$_TARGET_HOSTFILE_ARGS" ] ; then
    echo "Hostfile Args  : ${_TARGET_HOSTFILE_ARGS}"
fi
echo "======================"


###################################
# Wait for Pods to get DNS entries
###################################
_ACTUAL_CNS=`nslookup $_TARGET_CLUSTER | grep Name | wc -l`
until [ $_TARGET_CNS == $_ACTUAL_CNS ] ; do
    echo "Service ($_TARGET_CLUSTER): Waiting... Target: $_TARGET_CNS / Actual: $_ACTUAL_CNS"
    sleep 1
    _ACTUAL_CNS=`nslookup $_TARGET_CLUSTER | grep Name | wc -l`
done
echo "Service ($_TARGET_CLUSTER): Ready. Target: $_TARGET_CNS / Actual: $_ACTUAL_CNS"


###################################
# Wait for Pods to enter the 'Ready' state
###################################
_ACTUAL_CNS=`/opt/k8s/bin/kubectl -n $_NSPACE get pods -l $_SELECTOR | grep Running | wc -l`
until [ $_TARGET_CNS == $_ACTUAL_CNS ] ; do
    echo "Pods ($_TARGET_CLUSTER, $_SELECTOR): Waiting... Target: $_TARGET_CNS / Actual: $_ACTUAL_CNS"
    sleep 1
    _ACTUAL_CNS=`/opt/k8s/bin/kubectl -n $_NSPACE get pods -l $_SELECTOR | grep Running | wc -l`
done
echo "Pods ($_TARGET_CLUSTER, $_SELECTOR): Ready..."


###################################
# Save hostnames to hostfile if requested
###################################
if [ "x" != "x$_TARGET_HOSTFILE" ] ; then
    echo "Building Hostfile with hostnames: $_TARGET_HOSTFILE"
    _limit="$((_TARGET_CNS - 1))"
    if [ -f ${_TARGET_HOSTFILE} ] ; then
        rm ${_TARGET_HOSTFILE}
    fi
    touch ${_TARGET_HOSTFILE}
    for idx in $(seq 0 $_limit) ; do
        if [ "x" != "x$_TARGET_HOSTFILE_ARGS" ] ; then
            echo "${_TARGET_PREFIX}-${idx} $_TARGET_HOSTFILE_ARGS" >> ${_TARGET_HOSTFILE}
        else
            echo "${_TARGET_PREFIX}-${idx}" >> ${_TARGET_HOSTFILE}
        fi
    done
fi

###################################
# Save IPs to hostfile if requested
# - Alternatively we could save hostnames (since we have DNS).
#   However, by using the IP address we can reduce the launch
#   load on the DNS service.
###################################
if [ "x" != "x$_TARGET_HOSTFILE_IP" ] ; then
    echo "Building Hostfile with IPs: $_TARGET_HOSTFILE_IP"
    /opt/k8s/bin/kubectl -n $_NSPACE get pods -l $_SELECTOR --no-headers -o=custom-columns=NAME:.metadata.name,IP:.status.podIP  | sort --version-sort | awk "{print \$2 \"$_TARGET_HOSTFILE_ARGS\"}"  > ${_TARGET_HOSTFILE_IP}
fi

###################################
# All done
###################################
echo "Compute Nodes are ready"
