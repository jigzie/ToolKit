#!/bin/bash

awk "/Accounts_Gold/,/id/" ALL.wbk | grep  "id" | awk '{print $2}' | tr -d ' ' > WbkIds
while IFS="\n" read WbkID
do
	echo "ID of workbook: ${WbkID}"
	curl -u jigz:'D@t@m33rR0ck5!' -X POST 'https://idas.datameer.com/rest/job-execution?configuration='${WbkID}''
done < WbkIds
