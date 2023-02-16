#!/bin/bash -xe

# Usage:
#   $0 $endpoint_type $endpoint
#
# Assumptions:
#   - microk8s is installed


CSR_CONF="${CSR_CONF:-/var/snap/microk8s/current/certs/csr.conf.template}"

# Configure SAN for the control plane endpoint
# The apiservice-kicker will recreate the certificates and restart the service as needed
sed "/^DNS.1 = kubernetes/a${1}.100 = ${2}" -i "${CSR_CONF}"

# ensure csr.conf is updated
snap set microk8s hack.update.csr="$(date)"
#microk8s refresh-certs --cert front-proxy-client.crt
#microk8s refresh-certs --cert server.crt
snap restart microk8s.daemon-kubelite
microk8s status --wait-ready


