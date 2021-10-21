#!/bin/bash

## DEBUG MODE
if [ $DEBUG == "true" ]; then
  set -x
fi


## Variable
NETWORK_NAME=${1:-ocp4-private}
BRIDGE_NAME=${NETWORK_NAME}
DOMAIN_NAME=private
CIDR=${2:-192.168.200}

NETWORK_XML=${WORK_DIR}/additional_network.xml

## Exit if the file is existi.
if [ -f $NETWORK_XML ]; then
  exit 0
fi

## Add Network

cat <<EOF > ${NETWORK_XML} 
<network>
  <name>${NETWORK_NAME}</name>
  <bridge name='${BRIDGE_NAME}' stp='on' delay='0'/>
  <domain name='${DOMAIN_NAME}' localOnly="yes" />
  <ip address='${CIDR}.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='${CIDR}.1' end='${CIDR}.254' />
    </dhcp>
  </ip>
</network>
EOF

virsh net-define --file $NETWORK_XML
virsh net-autostart $NETWORK_NAME
virsh net-start $NETWORK_NAME
