#!/bin/bash

NODEROLE="${1}"
NUM=${2}


for i in $(seq 0 $((${NUM} - 1))); 
do
  virsh autostart ocp4-${NODEROLE}${i}
done
