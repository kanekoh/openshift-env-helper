#!/bin/bash

if [ $INSTALL_ODF != "true" ]; then
  exit 0
fi

bash install_clo.sh

bash deploy_efk.sh
