#!/bin/bash
#Uploader Script
COUNTER=0
while IFS=: read serverIP serverName schemaName tableList 
do
	echo "Name of Items: $tableList Jigz"
	COUNTER=$((COUNTER+1))
	echo "Executing Read Line: $COUNTER"
	IFS="," read -a array <<< ${tableList}
	for tablename in ${array[@]} 
	do
    		echo "FileName: $tablename.json"
	 	#sed 's/mstephenson/admin/g' $tablename.template > $tablename.json
                #Update Template Values for SchemaName and ServerName
                #sed 's/CR_PA/${schemaName}/g' ImportJob${array}REST.json > ImportJob${array}REST.json
                #sed 's/CR-SQL01/${serverName}/g' ImportJob${array}REST.json > ImportJob${array}REST.json
                #curl -u admin:admin -X POST -d @ImportJob${array}REST.json 'http://localhost:3050/rest/import-job'
                #sleep 3	
	done
done < ServerDatabaseList.txt
