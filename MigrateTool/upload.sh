#!/bin/bash
#Upload Script
###NOTES:
### Connection template is using MySQL as I did not have MSSQL jar
### The sdata file needs to be cleaned; basically you need to remote the \r that is at the end
### Trim the configFile of whitespace to avoid errors not captured
### artifacts folder needs to be created at the same level where you place this file (upload.sh)
### Try the overall process with one connection/one workbook execution; all artifacts can overload the system quickly.
### CLEANUP requires removing ALL artifacts/*json files & deleting the folder from Datameer where Connection/ImportJob is stored; script will recreate the correct folders


set COUNTER=0;
IFS=$'\n'

while IFS=':' read serverIP serverName schemaName tableList
do
	COUNTER=$((COUNTER+1));
        echo "Executing Read Line: $COUNTER";

	#######CONNECTIONS######## The created artifacts should be executed MANUALLY; connections cannot be invoked remotely.
	#Check if Connection was already built; if the json file for a particular DB-Schema exists then do not perform the actions
	if [ ! -f artifacts/Connections-${serverName}-${schemaName}.json ]; then
		sed 's/ServerName/'${serverName}'/g' artifacts/Connections.template > artifacts/Connections-${serverName}.tmp
		sed 's/SchemaName/'${schemaName}'/g' artifacts/Connections-${serverName}.tmp > artifacts/Connections-${serverName}-${schemaName}.json
		curl -u admin:admin -X POST -d @artifacts/Connections-${serverName}-${schemaName}.json 'http://localhost:3050/rest/connections'
	fi

	#########IMPORT JOBS####### Assumption: ImportJobs are always NEW so no need to check before creating artifact; will report dup.
	IFS="| " read -a jArray <<< "${tableList}"
	#echo "Table List: ${jArray[@]}"
	for tablename in "${jArray[@]}"; do
    		echo "Processing Import Job for Table: ${tablename}"
	 	sed 's/mstephenson/admin/g' artifacts/ImportJob${tablename}.template > artifacts/ImportJob${tablename}.tmp;
                #Update Template Values for SchemaName and ServerName;
                sed 's/SchemaName/'${schemaName}'/g' artifacts/ImportJob${tablename}.tmp > artifacts/ImportJob${tablename}-${schemaName}.tmp;
                sed 's/ServerName/'${serverName}'/g' artifacts/ImportJob${tablename}-${schemaName}.tmp > artifacts/ImportJob${tablename}-${schemaName}-${serverName}.json 
                #sed 's/TableName/'${tablename}'/g' artifacts/ImportJob${tablename}-${schemaName}.tmp > artifacts/ImportJob${tablename}-${schemaName}-${serverName}.json 
		echo "Adding Artifact: ImportJob${tablename}-${schemaName}-${serverName}.json to Datameer";
                curl -u admin:admin -X POST -d @artifacts/ImportJob${tablename}-${schemaName}-${serverName}.json 'http://localhost:3050/rest/import-job' > artifacts/pid.${tablename};
		#Cleanup temporary files
		ID=$(egrep -o "[0-9]+" artifacts/pid.${tablename}) 
		#echo "ID: ${ID}"
		######EXECUTE THE WORKBOOKS, assuming the earlier command was successful##########
		curl -u admin:admin -X POST 'http://localhost:3050/rest/job-execution?configuration='${ID}'' >> artifacts/wbk.results
		rm artifacts/*.tmp
		rm artifacts/pid.*
                #sleep 1	
	###### THE import Job is NOT executed yet; you will need to manually execute the Connections prior to running Import Jobs
	done
	###This completes the Import Jobs & it's execution
	##JIGZ: NOTE to SELF: Does it make sense to create a MASTER WORKBOOK with ALL Addresses table data as sheets; ALL Phones table data as sheets; to create MASTER table data
	### Thus create a MASTER Addresses table/sheet; UNION of all similar imports.
done < configFile
