#!/bin/bash
if [ $DEBUG == "true" ]; then
  set -x
fi

for i in bootstrap master{0..2} worker{0..1}
do
  virsh start ocp4-${i}
done
