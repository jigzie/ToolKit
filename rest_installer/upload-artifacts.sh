#!/bin/bash

# just traps ctrl_c incase we do that when echo is off

trap ctrl_c INT

# Functions

function ctrl_c(){

	stty echo
	echo
	echo "User exit..."
	echo
	exit 1

}

function split_info(){

	# take the artifact, ready to run curl

	_LINE="$1"
	_ARTIFACT=`echo "$_LINE"` 

	# to upload the JOSN dump later via curl we need to add @
	# in front of the file names

	_ARTIFACT="artifacts/"$_ARTIFACT
	
	# as the file name holds already the information of what type is it
	# we will use for it the REST API calls 

	_TYPE=`echo "$_LINE" | sed 's/-[0-9].*//'` 
	

	echo "Artifact: $_ARTIFACT" >> $LOG 2>&1
	echo "Type: $_TYPE" >> $LOG 2>&1
	post_artifacts $_ARTIFACT $_TYPE
}

function post_artifacts(){

	# change the IFS away from space so we can curl doesn't go crazy..

	IFS=%
	_ARTIFACT="$1"
	_TYPE="$2"
	echo -n "."
	# Add artifact to Datameer server
	_RESPONSE=$(curl -s -u ${DMUSERNAME}:${DMPASS} -X POST -d "@$_ARTIFACT" "$DMPROT://$DMHOST/rest/${_TYPE}")
	echo $_RESPONSE >> $LOG 2>&1
	sleep $SECBETWEENRQUESTS
	
	#If it is an datalink/importjob, automatically add in list for scheduling
	if [ $_TYPE = "import-job" ]
	then
	    post_new_artifact_for_execution $_RESPONSE
	fi
	
	#If it is a workbook, only add the ones that are scheduled.  The rest of the workbooks should
	#be data-driven-scheduled
	if [ $_TYPE = "workbook" ]
	then
	    _SCHEDULE_STR=$(cat $_ARTIFACT | awk -F': "' '/"pullType": "SCHEDULED",/ { print $2}')
	    if [[ $_SCHEDULE_STR == *"SCHEDULED"* ]] || [[ $_ARTIFACT == *"workbook-1000.json"* ]]
	    then
	        post_new_artifact_for_execution $_RESPONSE
	    fi
	fi
	
	if [[ $? -ne 0 ]]
	then
		echo "ERROR $_ARTIFACT to $_TYPE" >> $LOG 2>&1
	fi
}

function post_new_artifact_for_execution(){
    _RESPONSE="$1"
    _NEW_ARTIFACT_ID=$(echo $_RESPONSE | awk -F": " '/"configuration-id": / { print $2}')
    echo "$DMPROT://$DMHOST/rest/job-execution?configuration=$_NEW_ARTIFACT_ID" >> $ARTIFACTS_FOR_EXEC 2>&1
}

# Main Routine

# Ask user that they have all the following info is required
echo "============================================================================================================="
echo "Welcome to HUMv2 Installer"
echo
echo "Make sure to review the readme.txt file before proceeding"
echo
echo "This script will install HUMv2 in /Administration/HUMv2/ in Datameer virtual file system:"
echo
echo "Please note that HSQL is not supported at this time.  Datameer must be installed with MySQL as the metastore."
echo
echo "After installation, proceed configuring the connections and launch the jobs manually for the first time."
echo "You may also use the launch_hum.sh script to automatically submit all HUMv2 jobs for execution now."
echo "============================================================================================================="
echo
echo -n "Ready? (y/n):"
read _OK

if [[ $_OK != "y" ]]
then
	echo "User requested exit"
	exit 1
fi

# Declare some vars

FILES=artifacts.list
SHORTDATE=`date '+%y%m%d%M'`
LOG=/var/tmp/${SHORTDATE}_hum_import.log
ARTIFACTS_FOR_EXEC=./files_for_execution.list
WHERE=`pwd`
TO=`dirname \`ls -d $0\``

# makes sure we can cd to locate of the script and create the log

cd $TO || exit 1 # error message will be throw from cd so you will know why
touch $LOG || exit 1 # error thrown from touch

echo "Start importing artifacts -  `date`"
echo

if [[ -z $COMPANYNAME ]]
then
	while [[ -z $COMPANYNAME ]]
	do
		echo -n "Company Name :"
		read COMPANYNAME
	done
fi

echo -n "Environment Name (dev/staging/production/local). Default value is 'Production' :"
read ENVNAME
if [[ -z $ENVNAME ]]
then
	ENVNAME="Production"
fi

echo -n "Datameer Protocol (http/https). Default value is 'http' :"
read DMPROT
if [[ -z $DMPROT ]]
then
	DMPROT="http"
fi

echo -n "Datameer Hostname:Port. Default value is 'localhost:8080' :"
read DMHOST
if [[ -z $DMHOST ]]
then
    DMHOST="localhost:8080"
fi

echo -n "Datameer Admin Username (Default admin):"
read DMUSERNAME
if [[ -z $DMUSERNAME ]]
then
    DMUSERNAME="admin"
fi

stty echo
echo -n "Datameer Admin Password (Default admin):"
stty -echo
read DMPASS
echo 
# don't forget to turn echo back on
stty echo

if [[ -z $DMPASS ]]
then
    DMPASS="admin"
fi

echo -n "How many seconds between Artifact Creation Requests? (Default 1) :"
read SECBETWEENRQUESTS

if [[ -z $SECBETWEENRQUESTS ]]
then
    SECBETWEENRQUESTS=1
fi
PASSLENGTH=${#DMPASS}

echo	
echo "Company Name: $COMPANYNAME"
echo "Environment Name: $ENVNAME"
echo "Protocol: $DMPROT"
echo "Hostname: $DMHOST"
echo "Username: $DMUSERNAME"
echo "Password: ********"
echo "Log     : $LOG"
echo "Artifact Creation Request Interval: $SECBETWEENRQUESTS"
echo

echo -n "Ok to proceed? (y/n):"
read _OK

if [[ $_OK != "y" ]]
then
	echo "User requested exit"
	exit 1
fi

echo
echo "Reading ProductID from given Datameer instance"
PRODUCTID=$(curl -s -u ${DMUSERNAME}:${DMPASS} -X GET "${DMPROT}://${DMHOST}/license/product-id/")
echo "ProdutID: $PRODUCTID"

if [[ $PRODUCTID = "" ]]
then
	echo
	echo "Could not get an ProdutID!"
	echo "Please check hostname and port, username and password or connection to Datameer instance."
	echo 
	exit 1
fi

echo
echo "Patching artifact(s) with ProdutID, CompanyName, EnvName, DM Host details"
echo 

# now path for all existing jobs the preconfigured path with the variables to fill in
# for the search only include the JSON file within actual directory 
# find is done case insensitive to work around typos 
# replace can not be done case insensitive via I, as POSIX sed under OS X doesnt implement it  

# backup artifacts originals
mkdir artifacts_backup
cp artifacts/* artifacts_backup

grep --include=\*.json -irl %productId% ./artifacts/ | xargs sed -i -e "s/%productId%/${PRODUCTID}/g"
grep --include=\*.json -irl '%env:Name%' ./artifacts/ | xargs sed -i -e "s/%env:Name%/${ENVNAME}/g"
grep --include=\*.json -irl '%env:companyName%' ./artifacts/ | xargs sed -i -e "s/%env:companyName%/${COMPANYNAME}/g"
grep --include=\*.json -irl %dmProt% ./artifacts/ | xargs sed -i -e "s/%dmProt%/${DMPROT}/g"
grep --include=\*.json -irl %dmHost% ./artifacts/ | xargs sed -i -e "s/%dmHost%/${DMHOST}/g"
grep --include=\*.json -irl %dmUser% ./artifacts/ | xargs sed -i -e "s/%dmUser%/${DMUSERNAME}/g"


# probably this function could be used to path that file path within the artifacts 

# take each line of the file list and split

echo "Currently uploading artifact(s) to Datameer instance"
echo 

cat $FILES | while read _LINE
do
	split_info "$_LINE"
done

# cleanup
mv artifacts artifacts_processed
mv artifacts_backup artifacts

# this error checking is ... but does a job though!

if [[ `egrep -ic 'status.*failure|refused' $LOG | cut -f2 -d:` -ne 0 ]]
then
	echo
	echo "Error(s) possibly occured, please review $LOG"
	echo
else	
	echo
	echo "Completed importing artifacts - `date`"
	echo 
fi

cd $WHERE || exit 1
