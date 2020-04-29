#!/bin/bash -x
ocos="oc -n openshift-storage"
ocls="oc -n local-storage"

$ocos delete --timeout=5s deployment rook-ceph-tools
oc delete --timeout=5s -f https://raw.githubusercontent.com/jianzzha/ocp-ocs-install/master/ocs-cluster.yaml 
sleep 5

$ocos delete pvc --all
$ocos delete --timeout=5s pv --all
$ocos delete storagecluster --all --wait=true --timeout=5m --cascade=false
$ocos delete cephcluster --all --wait=true --timeout=5m
$ocos delete service --all --wait=true --timeout=5m
oc delete -f https://raw.githubusercontent.com/openshift/ocs-operator/release-4.3/deploy/deploy-with-olm.yaml
#$ocos delete deployment --all --wait=true --timeout=5m
#$ocos delete ds --all --wait=true --timeout=5m
#oc delete project openshift-storage --wait=true --timeout=5m
oc delete crd backingstores.noobaa.io bucketclasses.noobaa.io cephblockpools.ceph.rook.io cephclusters.ceph.rook.io cephfilesystems.ceph.rook.io cephnfses.ceph.rook.io cephobjectstores.ceph.rook.io cephobjectstoreusers.ceph.rook.io noobaas.noobaa.io ocsinitializations.ocs.openshift.io storageclusterinitializations.ocs.openshift.io storageclusters.ocs.openshift.io --wait=true --timeout=5m

#clean up local storage 
$ocls delete --all sc
$ocls delete pv --all
oc delete --timeout=5s -f https://raw.githubusercontent.com/jianzzha/ocp-ocs-install/master/local-storage-block.yaml 
oc delete --timeout=5s -f https://raw.githubusercontent.com/jianzzha/ocp-ocs-install/master/redhat-src-catalog.yaml 

echo "Local-storage and OCS are uninstalled, now wipe all devices on storage hosts!!!"

ssh core@baremetal "sudo rm -rf /var/lib/rook" 
ssh core@baremetal 'for d in nvme0n1 sdb sdc sdd sde sdf sdg sdh; do sudo pvremove --force /dev/$d ; sudo sgdisk -Z /dev/$d; done'
