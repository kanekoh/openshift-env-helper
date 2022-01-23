#!/bin/bash
if [ "$DEBUG" != "false" ]; then
  set -x
fi

WORKER_NUM=${1}
ODF_NUM=${2}

TMPFILE=$(mktemp /tmp/csr-XXXXX)

NUM=0
CSR_NUM=$(expr "$WORKER_NUM" \* 2)
if [ "${INSTALL_ODF}" == "true" ]; then
  CSR_NUM=$(expr $CSR_NUM + $ODF_NUM \* 2)
fi

TOTAL_WAIT=0
while [ $NUM -lt $CSR_NUM ] || [ $TOTAL_WAIT < 1200 ];
do
  oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve >> $TMPFILE 2> /dev/null
  echo -n "."

  sleep 5
  NUM=$(grep -i approved $TMPFILE | wc -l)
  TOTAL_WAIT=$(expr $TOTAL_WAIT + 5)
done

rm -f $TMPFILE
