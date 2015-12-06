#!/bin/bash
#Upload Script
###NOTES:
#### This script is to download the template: Workbook & Infographics to build a TAM Report view for each ACTIVE customer that has a TAM assigned.
#### Steps:
#### a. Download the template/Accounts_Gold.wbk workbook to Template.wbk
#### b. Download the template/Accounts.ifg infographic to Template.ifg
#### c. Update the Location of workbook to: /TAMReports/<CustomerName>/
#### d. Replace the FILTER from REPLACEME to <CustomerName>
#### e. Upload the workbook to idas
#### f. Run the workbook: Get the ID & see if a check is required (not desired yet!)
#### g. Update the Location of infographic to: /TAMReports/<CustomerName>/
#### i. Upload the infographics to idas

#####USER CONFIGURATIONS##########
workbookTemplateId=5866;
infographicTemplateId=956;
username="jigz";
password="PUTYOUROWNDAMNPASSWORD";
serverAddress="https://idas.datameer.com";
##################################


#### Each TIME you run: Download the latest SFDC accounts information

IFS=$'\n'
#Download the FULL list of workbooks/infographics; this is to know the location/path 
curl -u $username:''${password}'' -X GET ''${serverAddress}'/rest/workbook' > ALL.wbk
curl -u $username:''${password}'' -X GET ''${serverAddress}'/rest/infographics' > ALL.ifg

#Download the template workbook + infographics
curl -u $username:''${password}'' -X GET ''${serverAddress}'/rest/workbook/5866' > Template.wbk
curl -u $username:''${password}'' -X GET ''${serverAddress}'/rest/infographics/956' > Template.ifg

echo "Templates Available!!!"

#while IFS=':' read serverIP serverName schemaName tableList
while IFS=',' read CustomerName TAM Type
do

	#### CLEANSE the customer name of special characters like ' & # " . and anything else
	CustomerName=$(echo "${CustomerName}" | sed "s/[&.!@#$%^*()]/ /g")
	echo "New CustomerName=${CustomerName}"
	##Customer Name Variations: American Airlines, AT&T, CitiGroup vs. Citi Corp, etc... MAYBE the best solution is for TAM to use the filter themselves?
	#Replace ALL special characters: AT&T should be ATT OR Datameer,Inc. should be Datameer Inc OR () or any other thing that Datameer won't allow in name like single quote/etc
	#How to identify between American Airlines=American.* vs. American Express=American.*
	#Maybe use reverse token? then .*corp will be a match for many????
	REPLACEME_str=""
	IFS=" "
	for token in $CustomerName; do
		##Basically would like to change "Charles Schwab" to "Charles.*|Charles.*Schwab" 
		#echo "TOKEN: ${token}"
		REPLACEME_str="${REPLACEME_str}${REPLACEME_str%?}${token}.*|"	
		#REPLACEME_str="${REPLACEME_str%?}"
	done
	REPLACEME_str="${REPLACEME_str%?}"

	REPLACEME_str1=$(echo "${REPLACEME_str}"|awk '{print tolower($0)}')
	echo "Generating report for ${TAM}/${CustomerName}"
	echo "ReplaceMe String: ${REPLACEME_str1}"
	####READ the template workbook & replace the REPLACEME text with the newly built REGEX string
	cat Template.wbk | sed "s/REPLACEME/${REPLACEME_str1}/g"| sed "s/\/Template/\/${TAM}\/${CustomerName}/g" > Template1.wbk
	curl -u $username:''${password}'' -X POST -d @Template1.wbk ''${serverAddress}'/rest/workbook' > pid.wbk;
	
	RESULT=$(grep "already exists" pid.wbk | wc -l| tr -d ' ')
	echo "RESULT=${RESULT}"
	if [ "${RESULT}"=="1" ]; then
        	#Check if the object already exists; if so run the update.
		ID=$(awk "/${CustomerName}/,/id/" ALL.wbk | grep  "id" | awk '{print $2}' | tr -d ' ')
		echo "Workbook ID: ${ID}"
		curl -u $username:''${password}'' -X PUT -d @Template1.wbk ''${serverAddress}'/rest/workbook/'${ID}'' > pid.update.wbk
	else
		ID=$(egrep -o "[0-9]+" pid.wbk | tr -d ' ')
		echo "Workbook ID : ${ID}"			
	fi
	####Execute the workbook so infographics is ready to open
	echo "Execute the workbook"
	echo ''${serverAddress}'/rest/job-execution?configuration='${ID}''
	curl -u $username:''${password}'' -X POST ''${serverAddress}'/rest/job-execution?configuration='${ID}'' > pid.exe
	
	###READ Inforgraphic template & GENERATE a new Infographic
	cat Template.ifg | sed "s/\/Template/\/${TAM}\/${CustomerName}/g"  > Template1.ifg
	curl -u $username:''${password}'' -X POST -d @Template1.ifg ''${serverAddress}'/rest/infographics' > pid.ifg
	RESULT_ifg=$(grep "already exists" pid.wbk | wc -l | tr -d ' ')
        if [ "${RESULT_ifg}"=="1" ]; then
                #Check if the object already exists; if so run the update.
                ID=$(awk "/${CustomerName}/,/id/" ALL.ifg | grep  "id" | awk '{print $2}' | tr -d ' ')
		curl -u $username:''${password}'' -X PUT -d @Template1.ifg ''${serverAddress}'/rest/infographics/'$ID'' > pid.ifg
        else    
                ID=$(egrep -o "[0-9]+" pid.ifg | tr -d ' ')
        fi	

	######Cleanup Routine; Also you can print it to a file before cleanup
	#cat pid.wbk pid.exe pid.ifg > Log.`date`.log
	rm pid.wbk pid.exe pid.ifg
	echo "Done Account: ${CustomerName}"
	sleep 1
done < configFile
