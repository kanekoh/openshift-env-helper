#!/bin/bash

WORKER_NUM=${1}

TMPFILE=$(mktemp /tmp/csr-XXXXX)

NUM=0
CSR_NUM=$(expr $WORKER_NUM \* 2)
while [ $NUM -lt $CSR_NUM ];
do
  oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve >> $TMPFILE 2> /dev/null
  echo -n "."

  sleep 5
  NUM=$(grep -i approved $TMPFILE | wc -l)
done

rm -f $TMPFILE
