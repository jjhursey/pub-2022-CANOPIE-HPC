.PHONY: help kustomize

# #################################
# Configuration from environment
# #################################
# Set a devel version
VERSION ?= $(shell git describe --tags --dirty --always)

# Image URL to use all building/pushing image targets
IMAGE_BUILD_CMD ?= podman build
IMAGE_PUSH_CMD ?= podman push
IMAGE_BUILD_EXTRA_OPTS ?=
IMAGE_REGISTRY ?= quay.io/USERNAME
IMAGE_TAG_NAME ?= $(VERSION)
IMAGE_EXTRA_TAG_NAMES ?=
IMAGE_K8S_ARCH ?= $(shell uname -m)
IMAGE_REPO ?= $(IMAGE_REGISTRY)/$(IMAGE_NAME)
IMAGE_TAG ?= $(IMAGE_REPO):$(IMAGE_TAG_NAME)
IMAGE_BASE_RHEL ?= registry.access.redhat.com/ubi8/ubi

IMAGE_EXTRA_TAGS := $(foreach tag,$(IMAGE_EXTRA_TAG_NAMES),$(IMAGE_REPO):$(tag))
IMAGE_WAITFOR := $(IMAGE_REGISTRY)/k8s-waitfor:$(IMAGE_TAG_NAME)
IMAGE_PMIX_BASE := $(IMAGE_REGISTRY)/k8s-pmix-base:$(IMAGE_TAG_NAME)
IMAGE_RUNTIME := $(IMAGE_REGISTRY)/k8s-runtime:$(IMAGE_TAG_NAME)
IMAGE_RUNTIME_WITH_PODMAN := $(IMAGE_REGISTRY)/k8s-runtime-with-podman:$(IMAGE_TAG_NAME)
IMAGE_MPI := $(IMAGE_REGISTRY)/k8s-mpi:$(IMAGE_TAG_NAME)
IMAGE_MPI_WITH_RUNTIME := $(IMAGE_REGISTRY)/k8s-mpi-with-runtime:$(IMAGE_TAG_NAME)

IMAGE_GROMACS := $(IMAGE_REGISTRY)/k8s-gromacs:$(IMAGE_TAG_NAME)
IMAGE_GROMACS_WITH_RUNTIME := $(IMAGE_REGISTRY)/k8s-gromacs-with-runtime:$(IMAGE_TAG_NAME)

IMAGE_NAS := $(IMAGE_REGISTRY)/k8s-nas:$(IMAGE_TAG_NAME)
IMAGE_NAS_WITH_RUNTIME := $(IMAGE_REGISTRY)/k8s-nas-with-runtime:$(IMAGE_TAG_NAME)

NAMESPACE ?= kube-pmix

WAITFOR_TIMEOUT ?= 5m

# Go defaults
GOOS=linux
GO=GOOS=$(GOOS) GO111MODULE=on CGO_ENABLED=0 GOFLAGS=-mod=vendor go
LDFLAGS= -ldflags "-s -w -X $(PACKAGE)/version.Version=$(VERSION)"
GO_CMD=go

help:
	@echo "============================================================"
	@echo "See README.md for more details"
	@echo "---------------------------"
	@echo "Building Images"
	@echo "---------------------------"
	@echo "export IMAGE_REGISTRY=quay.io/<my-user>"
	@echo "make images push-images"
	@echo ""
	@echo "---------------------------"
	@echo "Running a virtual cluster"
	@echo "---------------------------"
	@echo "Deploy the cluster:"
	@echo "make deploy-ssh-with-podman"
	@echo ""
	@echo "Login:"
	@echo "make login-ssh-with-podman"
	@echo ""
	@echo "Undeploy the cluster:"
	@echo "make undeploy-ssh-with-podman"
	@echo ""
	@echo "============================================================"

# #################################
# Building Images
# #################################
# Wait for pods to be started and available
image-waitfor:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE_RHEL=$(IMAGE_BASE_RHEL) \
	  --build-arg _K8S_ARCH=$(IMAGE_K8S_ARCH) \
	  -t $(IMAGE_WAITFOR) build/waitfor/

push-waitfor:
	$(IMAGE_PUSH_CMD) $(IMAGE_WAITFOR)

# OpenPMIx Base
image-pmix-base:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE_RHEL=$(IMAGE_BASE_RHEL) \
	  -t $(IMAGE_PMIX_BASE) build/pmix-base/

push-pmix-base:
	$(IMAGE_PUSH_CMD) $(IMAGE_PMIX_BASE)

# PMIx Runtime
image-runtime:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE=$(IMAGE_PMIX_BASE) \
	  -t $(IMAGE_RUNTIME) build/runtime/

push-runtime:
	$(IMAGE_PUSH_CMD) $(IMAGE_RUNTIME)

# PMIx Runtime + Podman
# "MPI_IMAGE" : Default Container Application to launch (envar)
image-runtime-with-podman:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE_RUNTIME=$(IMAGE_RUNTIME) \
	  --build-arg MPI_IMAGE=${IMAGE_MPI} \
	  -t $(IMAGE_RUNTIME_WITH_PODMAN) build/runtime-with-podman/

push-runtime-with-podman:
	$(IMAGE_PUSH_CMD) $(IMAGE_RUNTIME_WITH_PODMAN)

# MPI : Open MPI only (no PMIx Runtime)
image-mpi:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE=$(IMAGE_PMIX_BASE) \
	  -t $(IMAGE_MPI) build/mpi/

push-mpi:
	$(IMAGE_PUSH_CMD) $(IMAGE_MPI)

# MPI with PMIx Runtime : Open MPI
image-mpi-with-runtime:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE=$(IMAGE_RUNTIME) \
	  --build-arg IMAGE_BASE_MPI=$(IMAGE_MPI) \
	  -t $(IMAGE_MPI_WITH_RUNTIME) build/mpi-with-runtime/

push-mpi-with-runtime:
	$(IMAGE_PUSH_CMD) $(IMAGE_MPI_WITH_RUNTIME)

# GROMACS : GROMACS (without runtime)
image-gromacs:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE=$(IMAGE_MPI) \
	  -t $(IMAGE_GROMACS) build/gromacs/

push-gromacs:
	$(IMAGE_PUSH_CMD) $(IMAGE_GROMACS)

# GROMACS with PMIx Runtime : GROMACS
image-gromacs-with-runtime:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE=$(IMAGE_MPI_WITH_RUNTIME) \
	  -t $(IMAGE_GROMACS_WITH_RUNTIME) build/gromacs/

push-gromacs-with-runtime:
	$(IMAGE_PUSH_CMD) $(IMAGE_GROMACS_WITH_RUNTIME)

# NAS : NAS (without runtime)
image-nas:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE=$(IMAGE_MPI) \
	  -t $(IMAGE_NAS) build/nas-bench/

push-nas:
	$(IMAGE_PUSH_CMD) $(IMAGE_NAS)

# NAS with PMIx Runtime : NAS
image-nas-with-runtime:
	$(IMAGE_BUILD_CMD) \
	  --build-arg IMAGE_BASE=$(IMAGE_MPI_WITH_RUNTIME) \
	  -t $(IMAGE_NAS_WITH_RUNTIME) build/nas-bench/

push-nas-with-runtime:
	$(IMAGE_PUSH_CMD) $(IMAGE_NAS_WITH_RUNTIME)


# Everything
images: image-waitfor image-pmix-base image-runtime image-mpi image-mpi-with-runtime image-runtime-with-podman image-gromacs image-gromacs-with-runtime image-nas image-nas-with-runtime

push-images: push-waitfor push-pmix-base push-runtime push-mpi push-mpi-with-runtime push-runtime-with-podman push-mpi-with-runtime push-gromacs push-gromacs-with-runtime push-nas push-nas-with-runtime

# #################################
# Virtual Cluster:
#  - deploy-ssh : ssh-based
# #################################
yamls-base: kustomize
	cd config/virtualCluster/base && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR)

yamls-ssh: kustomize yamls-base
	cd config/virtualCluster/ssh && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)

yamls-ssh-with-mpi: kustomize yamls-base
	cd config/virtualCluster/ssh && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_MPI_WITH_RUNTIME) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_MPI_WITH_RUNTIME) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)

yamls-ssh-with-podman: kustomize yamls-base
	cd config/virtualCluster/ssh && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)
	cd config/virtualCluster/ssh-with-podman && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)

yamls-ssh-with-podman-unpriv: kustomize yamls-base
	cd config/virtualCluster/ssh && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)
	cd config/virtualCluster/ssh-with-podman-unpriv && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)

yamls-kubectl: kustomize yamls-base
	cd config/virtualCluster/kubectl && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)

yamls-kubectl-with-mpi: kustomize yamls-base
	cd config/virtualCluster/kubectl && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_MPI_WITH_RUNTIME) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_MPI_WITH_RUNTIME) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)

yamls-kubectl-with-podman: kustomize yamls-base
	cd config/virtualCluster/kubectl && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)
	cd config/virtualCluster/kubectl-with-podman && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)

yamls-kubectl-with-podman-unpriv: kustomize yamls-base
	cd config/virtualCluster/kubectl && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)
	cd config/virtualCluster/kubectl-with-podman-unpriv && \
	$(KUSTOMIZE) edit set image k8s-waitfor=$(IMAGE_WAITFOR) && \
	$(KUSTOMIZE) edit set image k8s-login=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set image k8s-compute=$(IMAGE_RUNTIME_WITH_PODMAN) && \
	$(KUSTOMIZE) edit set namespace $(NAMESPACE)


deploy-ssh: yamls-ssh
	cd config && $(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone virtualCluster/ssh | kubectl apply -f -

deploy-ssh-with-mpi: yamls-ssh-with-mpi
	cd config && $(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone virtualCluster/ssh | kubectl apply -f -

deploy-ssh-with-podman: yamls-ssh-with-podman
	$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/ssh-with-podman | kubectl apply -f -

deploy-ssh-with-podman-unpriv: yamls-ssh-with-podman-unpriv
	$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/ssh-with-podman-unpriv | kubectl apply -f -

deploy-kubectl: yamls-kubectl
	$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl | kubectl apply -f -

deploy-kubectl-with-mpi: yamls-kubectl-with-mpi
	$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl | kubectl apply -f -

deploy-kubectl-with-podman: yamls-kubectl-with-podman
	$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl-with-podman | kubectl apply -f -

deploy-kubectl-with-podman-unpriv: yamls-kubectl-with-podman-unpriv
	$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl-with-podman-unpriv | kubectl apply -f -


undeploy-ssh:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/ssh | kubectl delete -f -

undeploy-ssh-with-mpi:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/ssh | kubectl delete -f -

undeploy-ssh-with-podman:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/ssh-with-podman | kubectl delete -f - 

undeploy-ssh-with-podman-unpriv:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/ssh-with-podman-unpriv | kubectl delete -f - 

undeploy-kubectl:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl | kubectl delete -f - 

undeploy-kubectl-with-mpi:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl | kubectl delete -f - 

undeploy-kubectl-with-podman:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl-with-podman | kubectl delete -f - 

undeploy-kubectl-with-podman-unpriv:
	@$(KUSTOMIZE) build --load-restrictor LoadRestrictionsNone config/virtualCluster/kubectl-with-podman-unpriv | kubectl delete -f - 


login-ssh: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (ssh based)"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash

login-kubectl: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (kubectl based)"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash

login-ssh-with-mpi: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (ssh based with MPI)"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash

login-kubectl-with-mpi: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (kubectl based with MPI)"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash

login-ssh-with-podman: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (ssh with podman based)"
	@echo "-----"
	@echo "export MPI_IMAGE='${IMAGE_MPI}'"
	@echo "prterun --map-by ppr:1:node podman pull -q \$$MPI_IMAGE"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash

login-kubectl-with-podman: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (kubectl with podman based)"
	@echo "-----"
	@echo "export MPI_IMAGE='${IMAGE_MPI}'"
	@echo "prterun --map-by ppr:1:node podman pull -q \$$MPI_IMAGE"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash

login-ssh-with-podman-unpriv: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (ssh with podman based)"
	@echo "-----"
	@echo "export MPI_IMAGE='${IMAGE_MPI}'"
	@echo "prterun --map-by ppr:1:node podman pull -q \$$MPI_IMAGE"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash

login-kubectl-with-podman-unpriv: common-login-wait
	@echo "------------------------------------------------------------"
	@echo "Logging into the HPC Virtual Cluster (kubectl with podman based)"
	@echo "-----"
	@echo "export MPI_IMAGE='${IMAGE_MPI}'"
	@echo "prterun --map-by ppr:1:node podman pull -q \$$MPI_IMAGE"
	@echo "------------------------------------------------------------"
	@kubectl -n $(NAMESPACE) exec -it job/hpc-cluster-login -c login -- env COLUMNS=`tput cols` bash


# #################################
# Support Tooling
# #################################
common-login-wait:
	@echo "------------------------------------------------------------"
	@echo "Waiting for cluster to start..."
	@kubectl -n $(NAMESPACE) wait pods --timeout=$(WAITFOR_TIMEOUT) --for=condition=Ready -l hpcnode=login-node,job-name=hpc-cluster-login

get-waitfor-log:
	@kubectl logs pod/$$( kubectl get po | grep "cluster-login" | awk '{print $$1;}') -c job-waiter

# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

# Download controller-gen locally if necessary
CONTROLLER_GEN = $(PROJECT_DIR)/bin/controller-gen
controller-gen:
	@GOBIN=$(PROJECT_DIR)/bin GO111MODULE=on $(GO_CMD) install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.8.0

# Download kustomize locally if necessary
# KUSTOMIZE = $(PROJECT_DIR)/bin/kustomize
# kustomize:
# 	@GOBIN=$(PROJECT_DIR)/bin GO111MODULE=on $(GO_CMD) install sigs.k8s.io/kustomize/kustomize/v4@v4.5.2

KUSTOMIZE = $(shell which kustomize)
kustomize:
	@echo $(KUSTOMIZE)
