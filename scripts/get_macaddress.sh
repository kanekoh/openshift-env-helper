#!/bin/bash

virsh dumpxml ${1} | grep "mac address" | cut -d\' -f2
