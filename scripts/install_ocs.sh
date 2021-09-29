#!/bin/bash

if [ "$INSTALL_ODF" == "false" ]; then
  echo "No need to install Container Sotrage Operator."
  exit 0
fi

echo "Create New Project for container storage"
oc adm new-project openshift-storage
oc annotate project openshift-storage openshift.io/node-selector=''
oc label namespace openshift-storage openshift.io/cluster-monitoring=true

echo "Install Operator"
CHANNEL_VERSION=$(oc get packagemanifests -n openshift-marketplace ocs-operator -o jsonpath='{.status.defaultChannel}')


cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: ocs-operator-group
  namespace: openshift-storage
spec:
  targetNamespaces:
    - openshift-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ocs-operator
  namespace: openshift-storage
spec:
  channel: "${CHANNEL_VERSION}"
  installPlanApproval: Automatic
  name: ocs-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo "Wait for install succeeded."
RTN=1
while [ $RTN -ne 0 ];
do
  oc get csvs -n openshift-storage | grep Succeeded > /dev/null
  RTN=$?
  if [ $RTN -ne 0 ]; then
    echo -n "."
    sleep 5
  fi
done


cat <<EOF | oc apply -f -
---
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  manageNodes: false
  resources:
    mds:
      limits:
        cpu: 3
        memory: 8Gi
      requests:
        cpu: 1
        memory: 8Gi
  monDataDirHostPath: /var/lib/rook
  storageDeviceSets:
    - count: 1
      dataPVCTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 500Gi
          storageClassName: localblock
          volumeMode: Block
      name: ocs-deviceset
      placement: {}
      portable: false
      replica: 3
      resources:
        limits:
          cpu: 2
          memory: 5Gi
        requests:
          cpu: 1
          memory: 5Gi
EOF

echo "Wait for deploying succeeded."
RTN=1
while [ $RTN -ne 0 ];
do
  oc get storagecluster -n openshift-storage | grep Ready > /dev/null
  RTN=$?
  if [ $RTN -ne 0 ]; then
    echo -n "."
    sleep 5
  fi
done
