#!/bin/bash

if [ $INSTALL_ODF != "true" ]; then
  exit 0
fi

cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry
  namespace: openshift-image-registry
spec:
  storageClassName: "ocs-storagecluster-cephfs"
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
EOF

oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"pvc":{"claim": "registry"}}}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'

