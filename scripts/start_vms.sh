#!/bin/bash
if [ $DEBUG == "true" ]; then
  set -x
fi

WORKER_NUM=$(expr ${1} - 1)

for i in bootstrap master{0..2}
do
  virsh start ocp4-${i}
  sleep 5
done

for i in $(seq 0 ${WORKER_NUM})
do
  virsh start ocp4-worker${i}
  sleep 5
done

if [ ${INSTALL_ODF} != "true" ]; then
  exit 0
fi

for i in odf{0..2}
do
  virsh start ocp4-${i}
  sleep 5
done

