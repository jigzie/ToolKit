#!/bin/bash
# Artifact Extractor
###NOTES:
# This is to extract ALL the following artifacts from Datameer
# Perform this action before upgrade & after upgrade
# Invoke with Checker set to TRUE which will compare B4Upgrade AfterUpgrade artifacts 
# Report on any artifact failures (caused due to upgrade)

echo "Total Arguments: $#"
###USAGE
if [ $# -ne 1 -a $# -ne 3 ]
then
	echo "Usage: ./DatameerExporter.sh <artifactsStorage>"
	echo "OR"
	echo "Usage: ./DatameerExporter.sh <artifactsStorage> <compare:TRUE> <oldArtifactsStorageLocation>"
	echo "example: ./DatameerExporter.sh artifactsLatest TRUE artifactsOld"
	exit 65
fi

####GENERATE Folders######
echo "Generating.... $1"
mkdir -p $1

####Start the Engine....####
# Kind of artifacts
Artifacts=(connections import-job workbook export-job dashboard infographics)

#echo "${Artifacts[*]}"
#####Read the Artifacts Array & gather all artifacts#####
#####Create a folder Artifacts/<type> to store the results#####
#IFS=" " read -a artifactsArray <<< "${Artifacts}"
for artifactType in "${Artifacts[@]}"; do
	echo "Processing Artifact Type: '${artifactType}'"
	curl -u admin:admin -X GET 'http://localhost:2144/rest/'${artifactType}'' > $1/${artifactType}.ALL
	#Read that file & then process it for each individual artifact ID to get & store the id
	echo "Parsing ALL ${artifactType} artifacts" 
	mkdir -p $1/${artifactType}
	egrep '\"id\"' $1/${artifactType}.ALL | sed 's/"id": //g'| sed 's/ //g' > $1/${artifactType}.ALL.list
	while IFS='' read ID
	do
		echo "Downloading ${artifactType}: ${ID}"
		echo "EXE: curl -u admin:admin -X GET 'http://localhost:2144/rest/${artifactType}/${ID}' >> $1/${artifactType}/${ID}.json"
		curl -u admin:admin -X GET 'http://localhost:2144/rest/'${artifactType}'/'${ID}'' > $1/${artifactType}/${ID}.json
	done < $1/${artifactType}.ALL.list
	#Clean-up Code
	echo "Cleanup Code to remove temp files"
	rm -f $1/${artifactType}.ALL*
done

#####IF only download is required then we're ALL done.
if [ $# -ne 3 ]
then
	exit 0
fi

##### Artifacts downloaded now... if compare is set we're going to use the below code for compare
if [ $2 -eq "true" ]
then
	echo "We're comparing folders"
fi



#while IFS=':' read serverIP serverName schemaName tableList
#do
	#COUNTER=$((COUNTER+1));
        #echo "Executing Read Line: $COUNTER";
#
	########CONNECTIONS######## The created artifacts should be executed MANUALLY; connections cannot be invoked remotely.
	##Check if Connection was already built; if the json file for a particular DB-Schema exists then do not perform the actions
	#if [ ! -f artifacts/Connections-${serverName}-${schemaName}.json ]; then
		#sed 's/ServerName/'${serverName}'/g' artifacts/Connections.template > artifacts/Connections-${serverName}.tmp
		#sed 's/SchemaName/'${schemaName}'/g' artifacts/Connections-${serverName}.tmp > artifacts/Connections-${serverName}-${schemaName}.json
		#curl -u admin:admin -X POST -d @artifacts/Connections-${serverName}-${schemaName}.json 'http://localhost:3050/rest/connections'
	#fi
#
	##########IMPORT JOBS####### Assumption: ImportJobs are always NEW so no need to check before creating artifact; will report dup.
	#IFS="| " read -a jArray <<< "${tableList}"
	##echo "Table List: ${jArray[@]}"
	#for tablename in "${jArray[@]}"; do
    		#echo "Processing Import Job for Table: ${tablename}"
	 	#sed 's/mstephenson/admin/g' artifacts/ImportJob${tablename}.template > artifacts/ImportJob${tablename}.tmp;
                ##Update Template Values for SchemaName and ServerName;
                ##sed 's/SchemaName/'${schemaName}'/g' artifacts/ImportJob${tablename}.tmp > artifacts/ImportJob${tablename}-${schemaName}.tmp;
                #sed 's/ServerName/'${serverName}'/g' artifacts/ImportJob${tablename}-${schemaName}.tmp > artifacts/ImportJob${tablename}-${schemaName}-${serverName}.json 
                ##sed 's/TableName/'${tablename}'/g' artifacts/ImportJob${tablename}-${schemaName}.tmp > artifacts/ImportJob${tablename}-${schemaName}-${serverName}.json 
		#echo "Adding Artifact: ImportJob${tablename}-${schemaName}-${serverName}.json to Datameer";
                #curl -u admin:admin -X POST -d @artifacts/ImportJob${tablename}-${schemaName}-${serverName}.json 'http://localhost:3050/rest/import-job' > artifacts/pid.${tablename};
		##Cleanup temporary files
		#ID=$(egrep -o "[0-9]+" artifacts/pid.${tablename}) 
		##echo "ID: ${ID}"
		#######EXECUTE THE WORKBOOKS, assuming the earlier command was successful##########
		#curl -u admin:admin -X POST 'http://localhost:3050/rest/job-execution?configuration='${ID}'' >> artifacts/wbk.results
		#rm artifacts/*.tmp
		#rm artifacts/pid.*
#
		##Read the Workbook template & update one table information at a time
		##Question: Why to create the workbook when all it gets is data sources; no need to execute it as none of the sheet will be saved
		#
                ##sleep 1	
	####### THE import Job is NOT executed yet; you will need to manually execute the Connections prior to running Import Jobs
	#done
	####This completes the Import Jobs & it's execution
#done < configFile
