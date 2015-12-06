#!/bin/bash
# Artifact Extractor
#This script is for Customer: CITI
#This will download all import-jobs (Datalinks, Import Jobs) from the datameer instance
###USAGE
if [ $# -ne 2 ]
then
        clear
        echo "####################################################"
        echo "Usage: ./CitiDataLink.sh -downloadDir <dwnldDir>"
        echo "example: ./CitiDataLink.sh -downloadDir TmpDir"
        echo "####################################################"
        exit 65
fi

####Start the Engine....####
# Kind of artifacts
#Artifacts=(connections import-job workbook export-job dashboard infographics)
Artifacts=(import-job)
username='admin'
password='admin'
servername='localhost'
port='2144'

#Download Function Start
downloadArtifacts(){
	####GENERATE Folders######
	echo "Generating.... '$@' Folder"
	mkdir -p $1
	#echo "${Artifacts[*]}"
	#####Read the Artifacts Array & gather all artifacts#####
	#####Create a folder <directory>/<type> to store the results#####
	for artifactType in "${Artifacts[@]}"; do
		echo "Processing Artifact Type: '${artifactType}'"
		curl -u ${username}:${password} -X GET 'http://'${servername}':'${port}'/rest/'${artifactType}'' > $1/${artifactType}.ALL
		#Read that file & then process it for each individual artifact ID to get & store the id
		echo "Parsing ALL ${artifactType} artifacts" 
		mkdir -p $1/${artifactType}
		#shopt -s nocasematch
		####Infographics is special; it uses the self tag
		if [[ "${artifactType}" = "infographics" ]]
		then
			#echo "Infographics: ${artifactType}"
			egrep '\"self\"' $1/${artifactType}.ALL | sed 's/\"self\": "\/rest\/infographics\///g'|sed 's/"//g'|sed 's/ //g' > $1/${artifactType}.ALL.list
		else
			#echo "Infographics: ${artifactType}"
			egrep '\"id\"' $1/${artifactType}.ALL | sed 's/"id": //g'| sed 's/ //g' > $1/${artifactType}.ALL.list
		fi
		#Close case-insensitive search
		#shopt -u nocasematch
		while IFS='' read ID
		do
			echo "Downloading ${artifactType}: ${ID}"
			echo "EXE: curl -u ${username}:${password} -X GET 'http://'${servername}':'${port}'/rest/${artifactType}/${ID}' >> $1/${artifactType}/${ID}.json"
			curl -u ${username}:${password} -X GET 'http://'${servername}':'${port}'/rest/'${artifactType}'/'${ID}'' > $1/${artifactType}/${ID}.json
		done < $1/${artifactType}.ALL.list
		#Clean-up Code
		echo "Cleanup Code to remove temp files"
		rm -f $1/${artifactType}.ALL*
	done
	#THIS IS FOR CITI only
	grep lnk Citi/import-job/*.json | grep -Po '\d*.json' | grep -Po '\d*' > DL.id
	while IFS='' read ID
        do
        	echo "Executing ${ID}"
        	curl -u ${username}:${password} -X POST 'http://'${servername}':'${port}'/rest/job-execution?configuration='${ID}''
        done < DL.id
}
###Download Function End
echo "Start Datalink Download"
echo "Using Server:${servername} and Port:${port} and Username:${username}"
downloadArtifacts "$2"
echo "DONE.... Login to Datameer & check if Datalinks are executing." 
