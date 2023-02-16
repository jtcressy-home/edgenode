#!/bin/bash -xe

# Usage:
#   $0 true/false <ip autodetect string> <Delete ip pools and ds,only true during init stage>
#
# Assumptions:
#   - microk8s is installed
#   - calico is installed
#   - the current node is not part of a cluster (yet)

if [[ "${1}" = "false" && "${2}" = "" ]]; then
  echo "Will not configure Calico"
  exit 0
fi

CNI_YAML="/var/snap/microk8s/current/args/cni-network/cni.yaml"
microk8s status --wait-ready
# Stop calico-node and delete ippools to ensure no vxlan pools are left around.True only for first CP node during init install
if [[ "${3}" == "true" ]]; then
microk8s kubectl delete daemonset/calico-node -n kube-system || true
microk8s kubectl delete ippools --all || true
fi
# Update cni.yaml manifest for IPIP
if [[ "${1}" = "true" ]]; then
sed 's/CALICO_IPV4POOL_VXLAN/CALICO_IPV4POOL_IPIP/' -i "${CNI_YAML}"
sed 's/calico_backend: "vxlan"/calico_backend: "bird"/' -i "${CNI_YAML}"
sed 's/-felix-ready/-bird-ready/' -i "${CNI_YAML}"
sed 's/-felix-live/-bird-live/' -i "${CNI_YAML}"
fi
if [[ "${2}" != "" ]]; then
  sed "s/first-found/${2}/" -i "${CNI_YAML}"
fi

# Apply the new manifest
# (TODO): this should perhaps be a touch cni-needs-reload
microk8s kubectl apply -f "${CNI_YAML}"
