#!/bin/bash
# Artifact Download/Upload script; simple & efficient if the project is to take ALL artifacts
###USAGE
if [ $# -ne 1 -a $# -ne 2 ]
then
	echo "Usage: ./DatameerBuilder.sh <FolderName> <download|upload|both>"
	echo "example: ./DatameerBuilder.sh Cust_Download_Date download"
	echo "example: ./DatameerBuilder.sh Cust_Download_Date upload"
	exit 65
fi

####GENERATE Folders######
echo "Generating.... directory $1"
mkdir -p $1

#####Settings Configuration: Please update with your custom values######
##Set Global username & passwords
## DO NOT MOVE this code block
set userDownload='admin';
set pwdDownload='admin';
set userUpload='admin';
set pwdDownload='admin';

set downloadURL='http://localhost:8089/';
set uploadURL='http://localhost:8081/';

##Settings Configuration: Complete######


####Start the Engine....####
echo "Start YOUR engines!!!"
sleep 3
# Kind of artifacts
Artifacts=(connections import-job workbook export-job dashboard infographics)

###UPLOAD CODE FIRST#######
#####Check if -UPLOAD is requested, which means the earlier code should ONLY execute if -DOWNLOAD is requested
if [ "$2" == "upload" ];
then	
	echo "Ready for running upload......."
	sleep 3
        for artifactType in "${Artifacts[@]}"; do
		#Remove the older PID file to avoid unnecessary noise
		if [ -f ${artifactType}.pids ];
		then
			rm ${artifactType}.pids
		fi
        	#Read ALL artifact types in order, workbook creation fails if IJ does not exists which fails if conn does not exist
		#The artifactType definition at top dictates this...Artifacts=conn,IJ, WBK, exp..
                echo "NOW uploading ${artifactType}, if exists"
		if [ ! -f $1/${artifactType}/*.json ];
		then
			echo "NO artifacts to upload"	
		else
                	ls $1/${artifactType}/*.json > ${artifactType}.list
                       	while IFS='' read filename
                       	do
                               	#echo "curl -u '${userDownload}:${pwdDownload}' -X POST -d @'${filename}' 'http://localhost:8440/rest/'${artifactType}''"
                               	curl -u '${userDownload}:${pwdDownload}' -X POST -d @${filename} 'http://localhost:8440/rest/'${artifactType}'' >> ${artifactType}.pids
                       	done < ${artifactType}.list
                       	rm -f ${artifactType}.list
		fi
		sleep 2
		echo ""
        done
	echo ""
	echo "Done uploading artifacts; please check the *.pids file for success/failure messages"
	#Keep the exit so the script stops here if ONLY upload; @TE reported bug :)
	exit 0
fi
#####UPLOAD COMPLETE


###########DOWNLOAD/BOTH CODE#############
#####Read the Artifacts Array & gather all artifacts#####
#####Create a folder Artifacts/<type> to store the results#####
#Adding sensible code; which Customer would like to ALLOW download/upload from same box?
####THIS code is ON by default as download or both should always do download first & then upload
###NOTE: The code will do DOWNLOAD and then try to upload

echo "Start DOWNLOADS!!!!!"
for artifactType in "${Artifacts[@]}"; do
	echo "Processing Artifact Type: '${artifactType}'"
	curl -u '${userDownload}':'${pwdDownload}' -X GET 'http://localhost:8412/rest/'${artifactType}'' > $1/${artifactType}.ALL
	#Read that file & then process it for each individual artifact ID to get & store the id
	echo "Parsing ALL ${artifactType} artifacts" 
	mkdir -p $1/${artifactType}
	egrep '\"id\"' $1/${artifactType}.ALL | sed 's/"id": //g'| sed 's/ //g' > $1/${artifactType}.ALL.list
	while IFS='' read ID
	do
		echo "Downloading ${artifactType}: ${ID}"
		#echo "EXE: curl -u '${userDownload}':'${pwdDownload}' -X GET 'http://localhost:8412/rest/${artifactType}/${ID}' >> $1/${artifactType}/${ID}.json"
		curl -u '${userDownload}':'${pwdDownload}' -X GET 'http://localhost:8412/rest/'${artifactType}'/'${ID}'' > $1/${artifactType}/${ID}.json

		#####UPLOAD to next server; this server should be reachable from here
		#####Customer might have restrictions that you cannot hop over environments
		####CODE to do it in ONE step
		#####Apparently Tony Egan DOES NOT like simple life so wants a fancy script :)
		######NOTE: THIS IS NOT TESTED yet... so AS-IS Sale! No 3 days guarantee
		if [ "$2" == "both" ];
		then
			echo "Trying to upload at the same time... This is NOT tested yet"
			curl -u '${userUpload}':'${pwdUpload}' -X POST -d @$1/${artifactType}/${ID}.json 'http://localhost:8440/rest/'${artifactType}'' >> ${artifactType}.pids
		fi
		####CODE DONE for ONE step
	done < $1/${artifactType}.ALL.list
	#Clean-up Code
	echo "Cleanup Code to remove temp files"
	rm -f $1/${artifactType}.ALL*
done
