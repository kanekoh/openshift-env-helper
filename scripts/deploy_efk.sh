#!/bin/bash

oc create -f - <<EOF
apiVersion: "logging.openshift.io/v1"
kind: "ClusterLogging"
metadata:
  name: "instance"
  namespace: "openshift-logging"
spec:
  managementState: "Managed"
  logStore:
    type: "elasticsearch"
    retentionPolicy:
      application:
        maxAge: 1d
      infra:
        maxAge: 7d
      audit:
        maxAge: 7d
    elasticsearch:
      nodeCount: 1
      storage:
        storageClassName: "ocs-storagecluster-ceph-rbd"
        size: 100G
      resources:
        limits:
          memory: "16Gi"
        requests:
          memory: "100Mi"
      proxy:
        resources:
          limits:
            memory: 256Mi
          requests:
             memory: 56Mi
      redundancyPolicy: "ZeroRedundancy"
  visualization:
    type: "kibana"
    kibana:
      replicas: 1
  collection:
    logs:
      type: "fluentd"
      fluentd: {}
EOF
