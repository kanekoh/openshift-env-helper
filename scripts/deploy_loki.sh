

oc create -f - <<EOF
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: loki-storage
  namespace: openshift-logging
spec:
  generateBucketName: loki-storage
  storageClassName: openshift-storage.noobaa.io
EOF

export ACCESS_KEY=$(oc get secret loki-storage --template='{{ .data.AWS_ACCESS_KEY_ID }}' -n openshift-logging)
export ACCESS_SECRET_KEY=$(oc get secret loki-storage --template='{{ .data.AWS_SECRET_ACCESS_KEY }}' -n openshift-logging)
export BUCKET_NAME=$(oc get ob obc-openshift-logging-loki-storage --template='{{ .spec.endpoint.bucketName }}' | base64 -w0)
export BUCKET_HOSTNAME=$(oc get ob obc-openshift-logging-loki-storage --template='{{ .spec.endpoint.bucketHost }}')
export BUCKET_PORT=$(oc get ob obc-openshift-logging-loki-storage --template='{{ .spec.endpoint.bucketPort }}')

export BUCKET_ENDPOINT=$(echo ${BUCKET_HOSTNAME}:${BUCKET_PORT} | base64 -w0)

oc create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: logging-loki-s3
  namespace: openshift-logging
data:
  access_key_id: ${ACCESS_KEY}
  access_key_secret: ${ACCESS_SECRET_KEY}
  bucketnames: ${BUCKET_NAME}
  endpoint: ${BUCKET_ENDPOINT}
EOF


oc create -f - <<EOF
  apiVersion: loki.grafana.com/v1
  kind: LokiStack
  metadata:
    name: logging-loki
    namespace: openshift-logging
  spec:
    size: 1x.small
    storage:
      schemas:
      - version: v12
        effectiveDate: '2022-06-01'
      secret:
        name: logging-loki-s3
        type: s3
    storageClassName: ocs-storagecluster-ceph-rbd
    tenants:
      mode: openshift-logging
EOF

oc create -f - <<EOF
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  name: instance
  namespace: openshift-logging
spec:
  managementState: Managed
  logStore:
     type: lokistack
     lokistack:
       name: logging-loki
     collection:
       type: "vector"
  collection:
    type: vector
EOF
