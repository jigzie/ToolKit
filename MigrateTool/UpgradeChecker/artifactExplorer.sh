#!/bin/bash
# Artifact Extractor
###NOTES:
# A tool to Download, Migrate, Run the artifacts in Datameer
# Extend it to 
###


####Start the Engine....####
errParams=0
datameerSvr='localhost'
datameerPort='2144'
username='admin'
password='admin'
#artifacts=(connections import-job workbook export-job dashboard infographics)
artifacts=(connections,import-job,workbook,export-job,dashboard,infographics)
#artifacts=(connections)
downloadDir='tmp'
onlyCompare1='tmp'
onlyCompare2='tmp1'
downloadAndCompare1='tmp'
downloadAndCompare2='tmp1'
migrateSvr='localhost'
migratePort='2148'
Musername='admin'
Mpassword='admin'
MrunAll='false'

#FUNCTIONS
usage(){
	echo "#######"
	echo "#USAGE:./artifactExplorer.sh -datameerSvr:<localhost>:<port> -username:<username> -password:<password> -artifacts:<connections,import-job,etc> -downloadDir:<dirName> OR -onlyCompare:<dir1>:<dir2> OR -downloadandCompare:<dwnlddirName>:<cmpDir> -migrate:<localhost>:<8081> -Musername:<username> -Mpassword:<password> -MrunAll:<true|false>"
	echo "#######"
}
#Extract ALL parameters
extractParams(){
for arg in "$@"; do
	case "${arg}" in
		-datameerSvr:*:*)  
			echo "Argument ${arg}"
			echo "Sending Datameer Server Infofound"
    	;;
		-username:*)  
			echo "Argument ${arg}"
			echo  "Sending USERNAME"
    	;;
		-password:*)  
			echo "Argument ${arg}"
			echo  "Sending PASSWORD"
	   	;;
	   	-artifacts:*)  
			echo "Argument ${arg}"
			echo "Sending Artifacts found"
    	;;
	   	-downloadDir:*)  
			echo "Argument ${arg}"
			echo "Sending DOWNLOADDIR found"
    	;;
		-onlyCompare:*:*)  
			echo "Argument ${arg}"
			echo  "Sending ONLYCOMPARE"
    	;;
		-downloadAndCompare:*:*)  
			echo "Argument ${arg}"
			echo  "Sending Download & Compare"
    	;;
		-migrate:*:*)  
			echo "Argument ${arg}"
			echo  "Sending Migrate"
    	;;
		-Musername:*)  
			echo "Argument ${arg}"
			echo  "Sending Migrate USERNAME"
    	;;
		-Mpassword:*)  
			echo "Argument ${arg}"
			echo  "Sending MIGRATING PASSWORD"
    	;;
    	-MrunAll:*)  
			echo "Argument ${arg}"
			echo  "Sending MIGRATING & RUN"
    	;;
		*) 
			echo ""
			echo "*****ERROR: Argument ${arg}*****"
			echo ""
			((errParams++))
   		;;
	esac
done
}

#Download Function Start
downloadArtifacts(){
	####GENERATE Folders######
	echo "Generating.... '$@'"
	mkdir -p $1
	#echo "${Artifacts[*]}"
	#####Read the Artifacts Array & gather all artifacts#####
	#####Create a folder <directory>/<type> to store the results#####
	artifact=(${artifacts[@]/,/\ })
	echo "${artifact[@]}"
	exit 66
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

###USAGE
if [ $# -lt 1 ]
then
    echo "No Arguments provided.... Don't know what to do!!!!! EXITING"
    usage
    exit
fi

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
