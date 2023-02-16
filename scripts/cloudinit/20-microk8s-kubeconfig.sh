#!/bin/bash -xe


microk8s status --wait-ready

mkdir -p /root/.kube
microk8s config > /root/.kube/config
if [[ "${1}" != "" ]]; then
  microk8s config > "${1}"
fi
