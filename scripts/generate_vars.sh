#!/bin/bash

BASEDIR=$(dirname $0)
OCP_VERSION=$2

export BOOTSTRAP_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-bootstrap)

for i in {0..2}
do
  eval export MASTER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-master${i})
done

## TODO use WORKER_NUM environment variable
for i in {0..1}
do
  eval export WORKER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-worker${i})
done

WORK_DIR=$1

if [ "${INSTALL_ODF}" == "true" ]; then
  for i in {0..2}
  do
    eval export ODF${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-odf${i})
  done
  VARS_SCRIPT=./vars/vars-odf.yaml
else
  VARS_SCRIPT=./vars/vars.yaml
fi

${VARS_SCRIPT} ${WORK_DIR}  ${OCP_VERSION}
