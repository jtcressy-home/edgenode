#!/bin/bash -xe

# Usage:
#   $0 $new_dqlite_addr $new_dqlite_address
#
# Assumptions:
#   - microk8s is installed
#   - dqlite has been initialized on the node and is running

DQLITE="/var/snap/microk8s/current/var/kubernetes/backend"

microk8s status --wait-ready
while ! NODES_JSON=$(microk8s kubectl get nodes -o json); do
  echo "Failed querying nodes, retrying"
done

INTERNAL_IP=$(echo "$NODES_JSON" | jq -r '.items[].status.addresses[] | select(.type=="InternalIP") | .address')


grep "Address" "${DQLITE}/info.yaml" | sed "s/127.0.0.1/$INTERNAL_IP/" | tee "${DQLITE}/update.yaml"

while ! snap restart microk8s.daemon-k8s-dqlite; do
  echo "Failed to restart microk8s, will retry"
  sleep 5
done

