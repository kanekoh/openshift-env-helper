#!/bin/bash

WORKER_NUM=$(expr ${1} - 1)

for i in $(seq 0 ${WORKER_NUM})
do
  WORKER_DOMAIN=ocp4-worker${i}
  virsh destroy ${WORKER_DOMAIN}
  virsh undefine ${WORKER_DOMAIN} --remove-all-storage
done
