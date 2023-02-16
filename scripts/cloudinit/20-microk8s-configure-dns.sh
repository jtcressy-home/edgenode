#!/bin/bash -xe

# Usage:
#   $0 userHostDNS DNSIP [...]
#
# Assumptions:
#   - microk8s is installed
#   - microk8s apiserver is up and running

# enable community addons, this is for free and avoids confusion if addons are failing to install
microk8s status --wait-ready
microk8s enable community
DNS=""
if [ ${1} == "true" ]; then
  DNS=$(cat /etc/resolv.conf|grep nameserver|cut -f 2 -d " ")
fi
if [ "${2}" != "" ]; then
  DNS=${2}
fi
if [ "$DNS" != "" ]; then
   microk8s enable dns:$DNS
else
  microk8s enable dns
fi

microk8s status --wait-ready