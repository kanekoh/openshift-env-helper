#!/bin/bash
if [ $DEBUG == "true" ]; then
  set -x
fi

HELPER_IP=${1}
SSH_PUB_BASTION=${2}

RTN=1
while [ $RTN -ne 0 ];
do
  # Wait until helper node started
  sshpass -p changeme ssh-copy-id -o StrictHostKeyChecking=no -i ${SSH_PUB_BASTION} root@${HELPER_IP} > /dev/null 2>&1
  RTN=$?
  if [ $RTN -ne 0 ]; then
    sleep 5
    echo -n "."
  fi
done

