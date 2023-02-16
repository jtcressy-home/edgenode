#!/bin/bash -xe

# Check if installed version is same as the snap version and if yes skip
installedVersion=$(snap list microk8s |grep microk8s | awk '{ print $2 }')
packageVersion=$(snap info /opt/microk8s/snaps/microk8s.snap |grep "version:" | awk '{ print $2 }')
if [ $installedVersion  !=  $packageVersion ]; then
  echo "Diff k8s version... upgrading"
  /opt/microk8s/scripts/00-install-microk8s.sh
else
  echo "Same Version...not upgrading"
fi