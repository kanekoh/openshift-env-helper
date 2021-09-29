#!/bin/bash

for i in $(seq 0 2)
do
  DOMAIN=ocp4-odf${i}
  virsh destroy ${DOMAIN}
  virsh undefine ${DOMAIN} --remove-all-storage
done
