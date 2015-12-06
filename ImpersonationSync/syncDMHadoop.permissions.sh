#!/bin/bash
#set -x
rootFolder="/axp/dmr"
IFS=$'\n'

if [ $# -ne 1 ]
then
	echo ""
	echo "Script will take as input one filename, to use for execution"
        echo "Usage: ./syncDMHadoop.permissions.sh Artifacts.1K.sql"
	echo ""
        exit 10
fi

###Break the Artifacts.sql into 1000 lines each using
####Commands: 
#tail -n +1 Artifacts.sql | head -n 1000  > Artifacts.1K.sql
#tail -n +1001 Artifacts.sql | head -n 1000 > Artifacts.2K.sql 
#tail -n +2001 Artifacts.sql | head -n 1000 > Artifacts.3K.sql
#tail -n +3001 Artifacts.sql | head -n 1000 > Artifacts.4K.sql
#tail -n +4001 Artifacts.sql | head -n 1000 > Artifacts.5K.sql
#tail -n +5001 Artifacts.sql | head -n 1000 > Artifacts.6K.sql
#tail -n +6001 Artifacts.sql | head -n 1000 > Artifacts.7K.sql


rm UpdateArtifacts.commands
###Changing Artifact Permissions, joblogs/other directories should be later
while IFS='	' read  ID fileName owner artifactType
do
	clear
	echo "READ LINE: ${ID}, ${fileName}, ${owner}, ${artifactType}"
	if [ ${ID} == "id" ]; then
		echo "Skipping this line"
		#sleep 10
		continue	
	fi
	#Extract USERID to build permissions
	groupID=$(id ${owner} | grep -o gid=.* | awk '{print $1}'|grep -o \(.*\) |sed 's/(//g' |sed 's/)//g')
	echo "GROUPID: ${groupID}"	
	##Based on artifactType you need to change the folder name for the path
	if [ ${artifactType} == "IMPORT_JOB_EXTENSION" ]; then
		echo "This is IMPORT JOB"
		artifactLocation="importjobs/${ID}"
	elif [ ${artifactType} == "IMPORT_LINK_JOB_EXTENSION" ]; then
		echo "This is IMPORT JOB"
		artifactLocation="importlinks/${ID}"
	elif [ ${artifactType} == "EXPORT_JOB_EXTENSION" ]; then
		echo "This is IMPORT JOB"
		artifactLocation="exportjobs/${ID}"
	elif [ ${artifactType} == "UPLOAD_JOB_EXTENSION" ]; then
		echo "This is UPLOAD JOB"
		artifactLocation="fileuploads/${ID}"
	elif [ ${artifactType} == "WORKBOOK_EXTENSION" ]; then
		echo "This is WORKBOOK"
		artifactLocation="workbooks/${ID}"
	fi
  	#Command to execute: hadoop fs -chown -R ${user} ${rootFolder}/${artifactLocation}		
	echo "hadoop fs -chown -R ${owner}:${groupID} ${rootFolder}/${artifactLocation}"
	hadoop fs -chown -R ${owner}:${groupID} ${rootFolder}/${artifactLocation}
	echo "hadoop fs -chown -R ${owner}:${groupID} ${rootFolder}/${artifactLocation}" >> UpdateArtifacts.commands
done < $1

echo "">> UpdateArtifacts.commands
echo "Done: Artifact permission migration is complete."
