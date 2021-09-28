#!/bin/bash
if [ $DEBUG == "true" ]; then
  set -x
fi

HELPER_NODE=${1}

RTN=1

while [ $RTN -ne 0 ];
do
  virsh domstate ${HELPER_NODE} | grep "shut off" > /dev/null
  RTN=$?
  if [ $RTN -ne 0 ]; then
    sleep 5
  fi
  echo -n "."
done

