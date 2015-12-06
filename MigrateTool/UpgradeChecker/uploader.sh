#!/bin/bash

usage=0

if [ $# -lt 1 ]
then
    echo "No Arguments provided.... Don't know what to do!!!!! EXITING"
	echo ""
	echo "USAGE:./artifactExplorer.sh -datameerSvr:<localhost>:<port> -username:<username> -password:<password> -artifacts:<connections,import-job,etc> -downloadDir:<dirName> OR -onlyCompare:<dir1>:<dir2> OR -downloadandCompare:<dwnlddirName>:<cmpDir> -migrate:<localhost>:<8081> -Musername:<username> -Mpassword:<password> -MrunAll:<true|false>"
        exit
fi

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
			((usage++))
   		;;
	esac
done
}
extractParams "$@"
echo ""
echo "ERROR PARAMETERS: $usage"

