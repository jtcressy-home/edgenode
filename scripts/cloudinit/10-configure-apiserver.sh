#!/bin/bash -xe

# Usage:
#   $0 $endpoint_type $endpoint
#
# Assumptions:
#   - microk8s is installed
#   - iptables is installed

APISERVER_ARGS="${APISERVER_ARGS:-/var/snap/microk8s/current/args/kube-apiserver}"
CREDENTIALS_DIR="${CREDENTIALS_DIR:-/var/snap/microk8s/current/credentials}"
CSR_CONF="${CSR_CONF:-/var/snap/microk8s/current/certs/csr.conf.template}"

# Configure command-line arguments for kube-apiserver
echo "
--service-node-port-range=30001-32767
" >> "${APISERVER_ARGS}"

# Configure apiserver port
sed 's/16443/6443/' -i "${APISERVER_ARGS}"

# Configure apiserver port for service config files
sed 's/16443/6443/' -i "${CREDENTIALS_DIR}/client.config"
sed 's/16443/6443/' -i "${CREDENTIALS_DIR}/scheduler.config"
sed 's/16443/6443/' -i "${CREDENTIALS_DIR}/kubelet.config"
sed 's/16443/6443/' -i "${CREDENTIALS_DIR}/proxy.config"
sed 's/16443/6443/' -i "${CREDENTIALS_DIR}/controller.config"

# Configure SAN for the control plane endpoint
# The apiservice-kicker will recreate the certificates and restart the service as needed
sed "/^DNS.1 = kubernetes/a${1}.100 = ${2}" -i "${CSR_CONF}"

# ensure csr.conf is updated
snap set microk8s hack.update.csr="$(date)"

# delete kubernetes service to make sure port is updated
snap restart microk8s.daemon-kubelite
microk8s status --wait-ready
microk8s kubectl delete svc kubernetes

# redirect port 16443 to 6443
iptables -t nat -A OUTPUT -o lo -p tcp --dport 16443 -j REDIRECT --to-port 6443 -w 300
iptables -t nat -A PREROUTING   -p tcp --dport 16443 -j REDIRECT --to-port 6443 -w 300

