#!/bin/bash

WORK_DIR=../ocp4-workingdir

for i in odf{0..2}
do
  virt-install --name="ocp4-${i}" --vcpus=12 --ram=16384 \
  --disk path=/var/lib/libvirt/images/ocp4-${i}.qcow2,bus=virtio,size=120 \
  --disk path=/var/lib/libvirt/images/odf-${i}.qcow2,bus=virtio,size=500 \
  --os-variant rhel8.0 --network network=openshift4,model=virtio \
  --boot hd,network,menu=on --print-xml > ${WORK_DIR}/ocp4-$i.xml
  virsh define --file ${WORK_DIR}/ocp4-$i.xml
done
