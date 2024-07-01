#!/bin/bash

for i in $(seq 0 2)
do
  MASTER_DOMAIN=ocp4-master${i}
  virsh destroy ${MASTER_DOMAIN}
  virsh undefine ${MASTER_DOMAIN} --remove-all-storage
done
