#!/bin/bash
#Upload Script
###NOTES:
#### This script is to download the template: Workbook & Infographics & duplicate that using the configFile provided
#### The script leverages the templates to create a new workbook + infographic
#### The script will also run the new workbook
#### The workbook (template) has a FILTER which should contain the exact word REPLACEME; the script replaces that programmatically.
#####USER CONFIGURATIONS##########
set workbookTemplateId=5866;
set infographicTemplateId=956;
set username="username";
set password="password";
set serverAddress="https://www.DatameerServer.com:8080";
##################################


set COUNTER=0;
IFS=$'\n'
#Download the details of workbook/infographics once so that you can start updating things faster
curl -u ${username}:'${password}' -X GET '${serverAddress}/rest/workbook' > ALL.wbk
curl -u ${username}:'${password}' -X GET '${serverAddress}/rest/infographics' > ALL.ifg

#Download the EXACT workbook + infographics TEMPLATE
curl -u ${username}:'${password}' -X GET '${serverAddress}/rest/workbook/'${workbookTemplateId}'' > Template.wbk
curl -u ${username}:'${password}' -X GET '${serverAddress}/rest/infographics/'${infographicTemplateId}'' > Template.ifg

#echo "Templates Available!!!"


#Read the configFile in the same directory which has the following format
#CustomerName, Owner, Type
#For example: 
#Workday, Owner1, Enterprise
#Company A, James Bond, Enterprise

####Note: The script uses the first parameter as CustomerName to create a subfolder under the OWNER (username)
#### The new workbooks will be under the same folder structure where the template wbk/ifg resides
#### Outcome is a folder structure of James Bond/Company A
#### Outcome is a folder structure of Owner1/Workday

while IFS=',' read CustomerName OWNER Type
do

	#### CLEANSE the customer name of special characters like ' & # " . and anything else
	CustomerName=$(echo "${CustomerName}" | sed "s/[&.!@#$%^*()]/ /g")
	echo "New CustomerName=${CustomerName}"
	
	REPLACEME_str=""
	IFS=" "
	for token in $CustomerName; do
		##Basically would like to change "Workday Inc" to "Workday.*|Workday.*Inc" 	
		REPLACEME_str="${REPLACEME_str}${REPLACEME_str%?}${token}.*|"	
	done
	REPLACEME_str="${REPLACEME_str%?}"

	REPLACEME_str1=$(echo "${REPLACEME_str}"|awk '{print tolower($0)}')
	
	echo "Generating report for ${OWNER}/${CustomerName}"
	#echo "ReplaceMe String: ${REPLACEME_str1}"
	####READ the template workbook & replace the REPLACEME text with the newly built REGEX string
	cat Template.wbk | sed "s/REPLACEME/${REPLACEME_str1}/g"| sed "s/\/Template/\/${OWNER}\/${CustomerName}/g" > Template1.wbk
	curl -u ${username}:'${password}' -X POST -d @Template1.wbk '${serverAddress}/rest/workbook' > pid.wbk;
	
	RESULT=$(grep "already exists" pid.wbk | wc -l| tr -d ' ')
	echo "RESULT=${RESULT}"
	if [ "${RESULT}"=="1" ]; then
        	#Check if the object already exists; if so run the update.
		ID=$(awk "/${CustomerName}/,/id/" ALL.wbk | grep  "id" | awk '{print $2}' | tr -d ' ')
		#echo "Workbook ID: ${ID}"
		curl -u ${username}:'${password}' -X PUT -d @Template1.wbk '${serverAddress}/rest/workbook/'${ID}'' > pid.update.wbk
	else
		ID=$(egrep -o "[0-9]+" pid.wbk | tr -d ' ')
		#echo "Workbook ID : ${ID}"			
	fi
	
	
	####Execute the workbook so infographics is ready to open
	echo "Execute the workbook"
	#echo '${serverAddress}/rest/job-execution?configuration='${ID}''
	curl -u ${username}:'${password}' -X POST '${serverAddress}/rest/job-execution?configuration='${ID}'' > pid.exe
	
	###READ Inforgraphic template & GENERATE a new Infographic
	cat Template.ifg | sed "s/\/Template/\/${OWNER}\/${CustomerName}/g"  > Template1.ifg
	curl -u ${username}:'${password}' -X POST -d @Template1.ifg '${serverAddress}/rest/infographics' > pid.ifg
	RESULT_ifg=$(grep "already exists" pid.wbk | wc -l | tr -d ' ')
        if [ "${RESULT_ifg}"=="1" ]; then
                #Check if the object already exists; if so run the update.
                ID=$(awk "/${CustomerName}/,/id/" ALL.ifg | grep  "id" | awk '{print $2}' | tr -d ' ')
		curl -u ${username}:'${password}' -X PUT -d @Template1.ifg '${serverAddress}/rest/infographics/'$ID'' > pid.ifg
        else    
                ID=$(egrep -o "[0-9]+" pid.ifg | tr -d ' ')
        fi	

	######Cleanup Routine; Also you can print it to a file before cleanup
	#cat pid.wbk pid.exe pid.ifg > Log.`date`.log
	rm pid.wbk pid.exe pid.ifg
	echo "Done Account: ${CustomerName}"
	sleep 1
done < configFile
