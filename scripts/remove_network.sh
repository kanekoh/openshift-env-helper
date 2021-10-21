#!/bin/bash

## DEBUG MODE


## Variable
NETWORK_XML=${1}

if [ ! -f $NETWORK_XML ]; then
  exit 0
fi

TARGET_NETWORK_NAME=$(cat ${NETWORK_XML} | grep '<name' | awk -F'[<>]' '{print $3}')
virsh net-destroy $TARGET_NETWORK_NAME
virsh net-undefine $TARGET_NETWORK_NAME

## Exit 0 anyway
exit 0
