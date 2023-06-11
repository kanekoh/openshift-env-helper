#!/bin/bash

echo "Knative CLI install"
wget "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/serverless/latest/kn-linux-amd64.tar.gz"

tar -xzvf kn-linux-amd64.tar.gz -C /usr/bin/
mv /usr/bin/kn-linux-amd64 /usr/bin/kn

echo "Tekton CLI install"
wget "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/pipeline/latest/tkn-linux-amd64.tar.gz"

tar -xzvf tkn-linux-amd64.tar.gz -C /usr/bin/
