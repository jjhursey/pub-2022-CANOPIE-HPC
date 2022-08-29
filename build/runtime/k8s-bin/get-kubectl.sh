#!/bin/bash
K8S_VERSION=v1.23.4
wget -q https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl
chmod +x ./kubectl
