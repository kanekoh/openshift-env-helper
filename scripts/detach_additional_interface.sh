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

TMPFILE=$(mktemp /tmp/multus-XXXXX)

virsh list > $TMPFILE

grep running ${TMPFILE} | awk '{print $2}' | while read VMNAME
do
  echo "#### $VMNAME"
  virsh detach-interface --type bridge --persistent --live ${VMNAME}
done

rm -f $TMPFILE
