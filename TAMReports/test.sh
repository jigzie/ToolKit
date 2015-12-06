#!/bin/bash

awk "/Accounts_Gold/,/id/" ALL.wbk | grep  "id" | awk '{print $2}' | tr -d ' ' > WbkIds
while IFS="\n" read WbkID
do
	echo "ID of workbook: ${WbkID}"
done < WbkIds
