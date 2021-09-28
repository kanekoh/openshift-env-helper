#!/bin/bash

BASEDIR=$(dirname $0)

BOOTSTRAP_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-bootstrap)

for i in {0..2}
do
  eval MASTER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-master${i})
done

for i in {0..1}
do
  eval WORKER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-worker${i})
done

WORK_DIR=$1

cat <<EOF > ${WORK_DIR}/vars.yaml
---
disk: vda
helper:
  name: "helper"
  ipaddr: "192.168.7.77"
dns:
  domain: "example.com"
  clusterid: "ocp4"
  forwarder1: "192.168.7.1"
  forwarder2: "192.168.7.1"
dhcp:
  router: "192.168.7.1"
  bcast: "192.168.7.255"
  netmask: "255.255.255.0"
  poolstart: "192.168.7.10"
  poolend: "192.168.7.30"
  ipid: "192.168.7.0"
  netmaskid: "255.255.255.0"
bootstrap:
  name: "bootstrap"
  ipaddr: "192.168.7.20"
  macaddr: "${BOOTSTRAP_MAC}"
masters:
  - name: "master0"
    ipaddr: "192.168.7.21"
    macaddr: "${MASTER0_MAC}"
  - name: "master1"
    ipaddr: "192.168.7.22"
    macaddr: "${MASTER1_MAC}"
  - name: "master2"
    ipaddr: "192.168.7.23"
    macaddr: "${MASTER2_MAC}"
workers:
  - name: "worker0"
    ipaddr: "192.168.7.11"
    macaddr: "${WORKER0_MAC}"
  - name: "worker1"
    ipaddr: "192.168.7.12"
    macaddr: "${WORKER1_MAC}"
EOF
