
for i in 0 1 2; do
virsh destroy worker$i
virsh undefine worker$i
virsh vol-delete worker$i.qcow2 --pool default
done

for i in 0 1 2; do
virt-install -n worker$i --pxe --os-type=Linux --os-variant=rhel8.0 --ram=32768 --vcpus=16 --network network=ocp4-upi,mac=52:54:00:f9:8e:3$i --disk size=120,bus=scsi,sparse=yes --check disk_size=off --noautoconsole
done
sleep 300

for i in 0 1 2; do
virsh start worker$i
done

count=6
while ((count > 0)); do
  echo "waiting for Pending csr"
  if oc get csr | grep Pending; then
    csr=$(oc get csr | grep Pending | awk '{print$1}')
    oc adm certificate approve $csr
    ((count--))
  fi
  sleep 5
done

virsh attach-disk worker0 /dev/sdh vdc
virsh attach-disk worker1 /dev/sdg vdc
virsh attach-disk worker2 /dev/sdf vdc

for i in 0 1 2; do
oc label node worker$i cluster.ocs.openshift.io/openshift-storage=''
oc label node worker$i topology.rook.io/rack=rack0
done

oc apply -f https://raw.githubusercontent.com/jianzzha/ocp-ocs-install/master/redhat-src-catalog.yaml
sleep 10

oc create -f local-storage-block.yaml

sleep 120 
oc apply -f https://raw.githubusercontent.com/openshift/ocs-operator/release-4.3/deploy/deploy-with-olm.yaml

sleep 120
oc create -f ocs-cluster.yaml

