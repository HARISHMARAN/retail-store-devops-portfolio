#!/bin/bash
set -e

/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${cluster_certificate} \
  --apiserver-endpoint ${cluster_endpoint} \
  --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup-image=amazon-eks-node-1.28-v20231121'
