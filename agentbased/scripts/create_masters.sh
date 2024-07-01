#!/bin/bash
set -x

WORK_DIR=../ocp4-workingdir


for i in master{0..0}
do
  num=$(echo $i | rev | cut -c 1)
  virt-install --name="ocp4-${i}" --vcpus=8 --ram=17288 \
  --disk path=/var/lib/libvirt/images/ocp4-${i}.qcow2,bus=virtio,size=120 \
  --os-variant rhel8.0 --network network=${PRIVATE_NETWORK_NAME},model=virtio,mac=52:54:00:18:e8:9${num} \
  --boot hd,menu=on -c /var/lib/libvirt/ISO/${AGENT_ISO} \
  --graphics vnc,listen=0.0.0.0 --noautoconsole \
  --print-step 1 > ${WORK_DIR}/ocp4-$i.xml
  virsh define --file ${WORK_DIR}/ocp4-$i.xml
done
