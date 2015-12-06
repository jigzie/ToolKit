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

# Ask user that they have all the following info is required
echo "=================================================================================="
echo "Welcome to HUMv2 initial job launcher"
echo "This script will launch HUMv2 jobs that were recorded in files_for_execution.list."
echo
echo "Please exit if file is not availble and launch upload-artifacts.sh first."
echo "Review additional information in the readme.txt file."
echo "=================================================================================="
echo
echo -n "Ready? (y/n):"
read _OK

if [[ $_OK != "y" ]]
then
	echo "User requested exit"
	exit 1
fi


FILES=files_for_execution.list
SHORTDATE=`date '+%y%m%d%M'`
LOG=/var/tmp/${SHORTDATE}_hum_execution.log
WHERE=`pwd`
TO=`dirname \`ls -d $0\``

# makes sure we can cd to locate of the script and create the log

cd $TO || exit 1 # error message will be throw from cd so you will know why
touch $LOG || exit 1 # error thrown from touch

echo "Start scheduling one time execution for artifacts -  `date`"
echo

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

echo -n "How many seconds between Job Execution requests? (Default 1) :"
read SECBETWEENRQUESTS

if [[ -z $SECBETWEENRQUESTS ]]
then
    SECBETWEENRQUESTS=1
fi

echo
echo "Username               : $DMUSERNAME"
echo "Password               : ********"
echo "Log                    : $LOG"
echo "Job Submission Interval: $SECBETWEENRQUESTS"
echo

echo -n "Ok to proceed? (y/n):"
read _OK

if [[ $_OK != "y" ]]
then
	echo "User requested exit"
	exit 1
fi

echo

# schedule via REST
cat $FILES | while read _LINE
do
	echo "Artifact being submitted for execution: $_LINE"  >> $LOG 2>&1
	echo -n "."
	curl -s -u ${DMUSERNAME}:${DMPASS} -X POST "$_LINE" >> $LOG 2>&1
	sleep $SECBETWEENRQUESTS
done

# this error checking is ... but does a job though!

if [[ `egrep -ic 'status.*failure|refused' $LOG | cut -f2 -d:` -ne 0 ]]
then
	echo
	echo "Error(s) possibly occured, please review $LOG"
	echo
else	
	echo
	echo "Completed submitting artifacts for execution - `date`"
	echo 
fi

cd $WHERE || exit 1
