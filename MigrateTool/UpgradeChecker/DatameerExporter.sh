#!/bin/bash
# Artifact Extractor
###NOTES:
# This is to extract ALL the following artifacts from Datameer
# Perform this action before upgrade & after upgrade
# Invoke with Checker set to TRUE which will compare B4Upgrade AfterUpgrade artifacts 
# Report on any artifact failures (caused due to upgrade)
# 2: -downloadDir <downloadDir>
# 3: -onlyCompare <previousDir> <currentDir>
# 4: -downloadDir <downloadDir> -compareDir <compareDir>
###USAGE
if [ $# -ne 2 -a $# -ne 3 -a $# -ne 4 ]
then
	clear
	echo "ERROR: Incorrect number of parameters"
	echo "####################################################"
	echo "Usage: ./DatameerExporter.sh -downloadDir <dwnldDir>"
	echo "OR"
	echo "Usage: ./DatameerExporter.sh -downloadDir <dwnldDir> -compare <cmprDir>"
	echo "OR"
	echo "Usage: ./DatameerExporter.sh -onlyCompare <currentDir> <prevDir>"
	echo ""
	echo "example: ./DatameerExporter.sh -downloadDir DM2144"
	echo "example: ./DatameerExporter.sh -downloadDir DM300 -compare DM2144"
	echo "example: ./DatameerExporter.sh -onlyCompare DM2144 DM300"
	echo "####################################################"
	exit 65
fi

####Start the Engine....####
# Kind of artifacts
Artifacts=(connections import-job workbook export-job dashboard infographics)
#Artifacts=(workbook)
#Artifacts=(infographics)
username=''
password=''

#Download Function Start
downloadArtifacts(){
	####GENERATE Folders######
	echo "Generating.... '$@'"
	mkdir -p $1
	#echo "${Artifacts[*]}"
	#####Read the Artifacts Array & gather all artifacts#####
	#####Create a folder <directory>/<type> to store the results#####
	for artifactType in "${Artifacts[@]}"; do
		echo "Processing Artifact Type: '${artifactType}'"
		curl -u admin:admin -X GET 'http://localhost:2144/rest/'${artifactType}'' > $1/${artifactType}.ALL
		#Read that file & then process it for each individual artifact ID to get & store the id
		echo "Parsing ALL ${artifactType} artifacts" 
		mkdir -p $1/${artifactType}
		#shopt -s nocasematch
		####Infographics is special; it uses the self tag
		if [[ "${artifactType}" = "infographics" ]]
		then
			#echo "Infographics: ${artifactType}"
			egrep '\"self\"' $1/${artifactType}.ALL | sed 's/\"self\": "\/rest\/infographics\///g'|sed 's/"//g'|sed 's/ //g' > $1/${artifactType}.ALL.list
			egrep '\"id\"' $1/${artifactType}.ALL | sed 's/"id": //g'| sed 's/ //g' > $1/${artifactType}.ALL.list
		else
			#echo "Infographics: ${artifactType}"
			egrep '\"id\"' $1/${artifactType}.ALL | sed 's/"id": //g'| sed 's/ //g' > $1/${artifactType}.ALL.list
		fi
		#Close case-insensitive search
		#shopt -u nocasematch
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
}
###Download Function End


#######THIS IS ONLY FOR COMPARE CODE######
compareFolders(){
	##### Artifacts downloaded now... if compare is set we're going to use the below code for compare
	shopt -s nocasematch
		##### Check if the passed directory exists
		if [ ! -d "$1" -a ! -d "$2" ]
		then
			echo ""
			echo "Uh Oh!!! We expect a directory for $3"
			echo "Please retry"
			echo ""
			exit 65
		fi
		clear
		echo ""
		echo "#########################################"
        	echo "#Starting comparison of folders/artifacts#"
		echo "#########################################"
 		diff -r --brief $1 $2	
		echo ""
        	exit 0
	shopt -u nocasematch
}

if [ $# -eq 3 ]
then
	clear
	echo "Comparing Artifacts collected"
	compareFolders "$2" "$3"
else
	#Check which calls to make
	echo "Download Artifacts....."
	downloadArtifacts "$2"
	echo "Downloading Artifacts Completed Successfully...."
	if [ $# -eq 4 ]
	then
		echo "Comparing Folders/Artifacts...."
		compareFolders "$2" "$4"
	fi
fi

####This is to upload to the next server; same server will give error due to the existing artifacts
#READ the file names
#arrFiles=( $(ls ${*/*.json) )
#for fileName in "${arrFiles[@]}"; do
#	echo "Found File: $fileName"
#	curl -u admin:admin -X POST -d @'$fileName' 'http://SERVER:8080/rest/'$fileName''
#done
