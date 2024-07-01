#!/bin/bash
# TODO use variable for network name 

WORKER_NUM=$(expr ${1} - 1)

WORK_DIR=../ocp4-workingdir

for i in $(seq 0 ${WORKER_NUM})
do
  DOMAIN=ocp4-worker${i}
  virt-install --name="${DOMAIN}" --vcpus=12 --ram=32768 \
  --disk path=/var/lib/libvirt/images/${DOMAIN}.qcow2,bus=virtio,size=120 \
  --os-variant rhel8.0 --network network=${NETWORK_NAME},model=virtio,mac=52:54:00:18:e8:8${i} \
  --boot hd,menu=on -c /var/lib/libvirt/ISO/${AGENT_ISO} \
  --print-step 1 > ${WORK_DIR}/${DOMAIN}.xml
  virsh define --file ${WORK_DIR}/${DOMAIN}.xml
done
