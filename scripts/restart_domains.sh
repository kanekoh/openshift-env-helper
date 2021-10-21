#!/bin/bash

## DEBUG MODE
if [ $DEBUG == "true" ]; then
  set -x
fi

function wait_until_down () {
  VMNAME=$1
  STATE="dummy"
  while [ $STATE != "shut" ];
  do
    STATE=$(virsh list --all | grep $VMNAME | awk '{print $3}')
    if [ $STATE != "shut" ]; then
      echo -n "."
      sleep 5
    fi
  done

}

TMPFILE=$(mktemp /tmp/multus-XXXXX)

virsh list > $TMPFILE

grep running ${TMPFILE} | awk '{print $2}' | while read VMNAME
do
  echo "#### $VMNAME"
  virsh shutdown $VMNAME
done

grep running ${TMPFILE} | awk '{print $2}' | while read VMNAME
do
  echo "#### $VMNAME"
  wait_until_down $VMNAME
done

grep running ${TMPFILE} | awk '{print $2}' | while read VMNAME
do
  echo "#### $VMNAME"
  virsh start $VMNAME
done

rm -f $TMPFILE
