#!/bin/bash

BOOTSTRAP_DOMAIN=ocp4-bootstrap
virsh destroy ${BOOTSTRAP_DOMAIN}
virsh undefine ${BOOTSTRAP_DOMAIN} --remove-all-storage

