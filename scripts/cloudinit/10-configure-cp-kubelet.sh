#!/bin/bash -xe

#KUBELET_ARGS="${KUBELET_ARGS:-/var/snap/microk8s/current/args/kubelet}"

#vi "${KUBELET_ARGS}"

#snap restart microk8s.daemon-kubelite
microk8s status --wait-ready
CP_NODE_NAMES=$(microk8s kubectl get nodes --selector='node.kubernetes.io/microk8s-controlplane' -o json |  jq -r .items[].metadata.name)
for i in $CP_NODE_NAMES
do
microk8s kubectl label nodes $i node-role.kubernetes.io/control-plane=true --overwrite=true
done