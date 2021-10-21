#!/bin/bash

## DEBUG MODE
if [ $DEBUG == "true" ]; then
  set -x
fi


## Variables
NETWORK_XML=${WORK_DIR}/additional_network.xml

## Exit if the file is not existi.
if [ ! -f $NETWORK_XML ]; then
  exit 0
fi

TARGET_NETWORK_NAME=$(cat ${NETWORK_XML} | grep '<name' | awk -F'[<>]' '{print $3}')
TMPFILE=$(mktemp /tmp/multus-XXXXX)

virsh list > $TMPFILE

grep running ${TMPFILE} | awk '{print $2}' | while read VMNAME
do
  echo "#### $VMNAME"
  virsh attach-interface --type bridge --source ${TARGET_NETWORK_NAME} --model virtio --persistent --live  ${VMNAME}
done

rm -f $TMPFILE
