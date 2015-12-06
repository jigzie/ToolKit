#!/bin/bash
#Version: 1.5
#Comment 1: Build for ALL download/upload/both for Tony Egan
#Comment 2: Bug fix, upload did NOT stop after completion; add exit after upload routine
#Comment 3: Update usage information for users who won't read the script before execution! Duh!
#Comment 4: Add variables for easier update of script; ToServer & FromServer (maybe in future have a text file download.txt or upload.txt or both.txt to read from). Don't get paid enough for making it VERY user-friendly script :))
#Comment 5: Add logic to check if download/upload to same server with Both option is selected; DO NOT ALLOW.

####
#### ARTIFACT DOWNLOAD/UPLOAD SCRIPT; SIMPLE & EFFICIENT IF REQUIREMENT IS TO TAKE ALL ARTIFACTS (CONN, IJ, DL, WBK, IFG)
####
#####################USAGE######################
if [ $# -ne 1 -a $# -ne 2 ]
then
	echo "Usage: ./DatameerBuilder.sh <artifactsStorage> <download|upload|both>"
	echo "example: ./DatameerBuilder.sh Cust_Download_Date download"
	echo "example: ./DatameerBuilder.sh Cust_Download_Date upload"
	echo "Note: Artifacts Storage name cannot contain any special char or space; just one alphanumeric word"
	echo "Note: Options are case-sensitive so only supports download|upload|both"
	exit 65
fi

####################VARIABLES####################
fromSrv="localhost"
fromPort="8089"
fromUsr="admin"
fromPwd="admin"

toSrv="localhost"
toPort="8089"
toUsr="admin"
toPwd="admin"
#################################################

#########GENERATE Folders############
echo "Generating.... directory $1"
mkdir -p $1

########Start the Engine....#########
echo "Start YOUR engines!!!"
sleep 3
# Kind of artifacts
Artifacts=(connections import-job workbook export-job dashboard infographics)

########UPLOAD CODE FIRST############
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
                               	#echo "curl -u admin:admin -X POST -d @'${filename}' 'http://localhost:8440/rest/'${artifactType}''"
                               	#curl -u admin:admin -X POST -d @${filename} 'http://localhost:8440/rest/'${artifactType}'' >> ${artifactType}.pids
                               	curl -u $toUsr:$toPwd -X POST -d @${filename} 'http://'${toSrv}':'${toPort}'/rest/'${artifactType}'' >> ${artifactType}.pids
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

################UPLOAD COMPLETE##########################


###########DOWNLOAD/BOTH CODE#############
#####Read the Artifacts Array & gather all artifacts#####
#####Create a folder Artifacts/<type> to store the results#####
#Adding sensible code; which Customer would like to ALLOW download/upload from same box?
####THIS code is ON by default as download or both should always do download first & then upload

#Check: Servers are identical, Ports are identical & Customer wants to do download and upload
if [[ "$fromSrv" == "$toSrv" && "$fromPort" == "$toPort" && $2 == "both" ]]; 
then
	echo "Download & Upload to the same server:Port is not supported; Duplicate errors will occur"
	echo "Use ./DatameerBuilder.sh <Folder> <Download|Upload>"
	echo "Please re-run correctly"
	exit 65
fi

echo "Start DOWNLOADS!!!!!"
sleep 1
for artifactType in "${Artifacts[@]}"; do
	echo "Processing Artifact Type: '${artifactType}'"
	curl -u $fromUsr:$fromPwd -X GET 'http://'${fromSrv}':'${fromPort}'/rest/'${artifactType}'' > $1/${artifactType}.ALL
	#Read that file & then process it for each individual artifact ID to get & store the id
	echo "Parsing ALL ${artifactType} artifacts" 
	mkdir -p $1/${artifactType}
	egrep '\"id\"' $1/${artifactType}.ALL | sed 's/"id": //g'| sed 's/ //g' > $1/${artifactType}.ALL.list
	while IFS='' read ID
	do
		echo "Downloading ${artifactType}: ${ID}"
		#echo "EXE: curl -u admin:admin -X GET 'http://localhost:8412/rest/${artifactType}/${ID}' >> $1/${artifactType}/${ID}.json"
		curl -u $fromUsr:$fromPwd -X GET 'http://'${fromSrv}':'${fromPort}'/rest/'${artifactType}'/'${ID}'' > $1/${artifactType}/${ID}.json

		#####UPLOAD to next server; this server should be reachable from here
		#####Customer might have restrictions that you cannot hop over environments
		####CODE to do it in ONE step
		######NOTE: THIS IS NOT TESTED yet... so AS-IS Sale! No return policy 
		if [ "$2" == "both" ];
		then
			echo "Trying to upload at the same time... This is NOT tested yet"
			curl -u $toUsr:$toPwd -X POST -d @$1/${artifactType}/${ID}.json 'http://'${toSrv}':'${toPort}'/rest/'${artifactType}'' >> ${artifactType}.pids
		fi
		####CODE DONE for ONE step
	done < $1/${artifactType}.ALL.list
	#Clean-up Code
	echo "Cleanup Code to remove temp files"
	rm -f $1/${artifactType}.ALL*
done
