#!/bin/bash
#Upload Script
set COUNTER=0;
IFS=$'\n'
while IFS=':' read serverIP serverName schemaName tableList
do
	#echo "READ: ${serverIP}"
	#Break into variables
	#IFS=":" serverIP serverName schemaName tableList
	echo "Items: ${tableList}";
	COUNTER=$((COUNTER+1));
	echo "Executing Read Line: $COUNTER";

	IFS="| " read -a jArray <<< "${tableList}"
	echo "Table List: ${jArray[@]}"
	for tablename in "${jArray[@]}"; do
    		echo "Processing Table: ${tablename}"
	 	sed 's/mstephenson/admin/g' ImportJob${tablename}.template > ImportJob${tablename}.tmp;
                #Update Template Values for SchemaName and ServerName;
                sed 's/CR_PA/'${schemaName}'/g' ImportJob${tablename}.tmp > ImportJob${tablename}-${schemaName}.tmp;
                sed 's/CR-SQL01/'${serverName}'/g' ImportJob${tablename}-${schemaName}.tmp > ImportJob${tablename}-${schemaName}-${serverName}.json 
		echo "Adding Artifact: ImportJob${tablename}-${schemaName}-${serverName}.json to Datameer";
                curl -u admin:admin -X POST -d @ImportJob${tablename}-${schemaName}-${serverName}.json 'http://localhost:3050/rest/import-job';
		rm *.tmp
                #sleep 1	
	done
done < sdata
