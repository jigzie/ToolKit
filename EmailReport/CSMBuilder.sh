#!/bin/bash
#Upload Script
###NOTES:
#### This script is to download the template: Workbook & Infographics to build a CSM Report view for each ACTIVE customer that has a CSM assigned.
#### Steps:
#### a. Download the template/Accounts_Gold.wbk workbook to Template.wbk
#### b. Download the template/Accounts.ifg infographic to Template.ifg
#### c. Update the Location of workbook to: /CSMReports/<CustomerName>/
#### d. Replace the FILTER from REPLACEME to <CustomerName>
#### e. Upload the workbook to idas
#### f. Run the workbook: Get the ID & see if a check is required (not desired yet!)
#### g. Update the Location of infographic to: /CSMReports/<CustomerName>/
#### i. Upload the infographics to idas


#### Each TIME you run: Download the latest SFDC accounts information
#Cleanup
rm -rf WbkIDs.list

set COUNTER=0;
IFS=$'\n'
#Download the FULL list of workbooks/infographics; this is to know the location/path 
curl -u jigz:'D@t@m33rR0ck5!' -X GET 'https://idas.datameer.com/rest/workbook' > ALL.wbk
#curl -u jigz:'D@t@m33rR0ck5!' -X GET 'https://idas.datameer.com/rest/infographics' > ALL.ifg

#Download the template workbook + infographics
curl -u jigz:'D@t@m33rR0ck5!' -X GET 'https://idas.datameer.com/rest/workbook/8993' > Template.wbk
#curl -u jigz:'D@t@m33rR0ck5!' -X GET 'https://idas.datameer.com/rest/infographics/956' > Template.ifg

###Download SFDC AccountName Information, CSM & their Email address
###JIGZ: Enable next 5 line
curl -u jigz:'D@t@m33rR0ck5!' -X GET 'https://idas.datameer.com/rest/data/workbook/8994/Accounts/download' > Accounts.csv
cat Accounts.csv | sed 's/\"\,\"/\|/g' | sed 's/\"//g' > AccountsInfo.tmp.csv
#Remove first line from accounts; CSV header information
awk 'NR>1' AccountsInfo.tmp.csv > AccountsInfo.csv
rm AccountsInfo.tmp.csv Accounts.csv
#Drop other CSM email & only send to subscribed
grep -i jigz AccountsInfo.csv > JigzAccounts.csv
mv JigzAccounts.csv AccountsInfo.csv

	echo "Templates Downloaded!!!"
	while IFS='|' read CustomerName CSM Email
	do
		#### CLEANSE the customer name of special characters like ' & # " . and anything else
		CustomerName=$(echo "${CustomerName}" | sed "s/['&.!@#$%^*,()]/ /g")
		CSM=$(echo "${CSM}" | sed "s/[;]/_/g")
		echo "New CustomerName=${CustomerName}"
	
		###Special handling for Telefonica; characters not allowed in workbook name	
		CustomerWorkbookName=$(echo "${CustomerName}" | sed "s/.*Germany.*/Telefonica/g")
		CustomerWorkbookName=$(echo "${CustomerName}" | sed "s/.*Kohl.*/Kohls/g")
		#echo "Workbook Name=${CustomerWorkbookName}"
		REPLACEME_str=".*${CustomerName}.*"

		#REPLACEME_str1=$(echo "${REPLACEME_str}"|awk '{print tolower($0)}')
		REPLACEME_str1=$(echo "${REPLACEME_str}")
		clear
		echo "Generating report for ${CustomerName}"
		echo "ReplaceMe String: ${REPLACEME_str1}"
		####READ the template workbook & replace the REPLACEME text with the newly built REGEX string
		#cat Template.wbk | sed "s/REPLACE_ME/${REPLACEME_str1}/g"| sed "s/\/Template/\/${CSM}\/${CustomerName}/g" > Template1.wbk
		cat Template.wbk | sed "s/REPLACE_ME/${REPLACEME_str1}/g"| sed "s/Sources\/Customer_Report_Template/${CustomerWorkbookName}_Report/g" | sed "s/Customer_Report_Template/${CustomerWorkbookName}_Report/g"> Template1.wbk
		curl -u jigz:'D@t@m33rR0ck5!' -X POST -d @Template1.wbk 'https://idas.datameer.com/rest/workbook' > pid.wbk;
		
		RESULT=$(grep "already exists" pid.wbk | wc -l| tr -d ' ')
		#echo "RESULT=${RESULT}"
		if [ "${RESULT}" -eq "1" ]; then
			sleep 1
			#echo "Updating"
			#Check if the object already exists; if so run the update.
			ID=$(awk "/\/${CustomerWorkbookName}_Report\.wbk/,/id/" ALL.wbk | grep  "id" | awk '{print $2}' | tr -d ' ')
			echo "Workbook ID: ${ID}"
			curl -u jigz:'D@t@m33rR0ck5!' -X PUT -d @Template1.wbk 'https://idas.datameer.com/rest/workbook/'${ID}'' > pid.update.wbk
		else
			sleep 1
			#echo "Adding NEW"
			ID=$(egrep -o "[0-9]+" pid.wbk | tr -d ' ');
			echo "Workbook ID : ${ID}"			
		fi
		####Execute the workbook so infographics is ready to open
		echo "Execute the workbook"
		echo "${ID}|${CustomerName}|${Email}" >> WbkIDs.list
		echo 'https://idas.datameer.com/rest/job-execution?configuration='${ID}''
		curl -u jigz:'D@t@m33rR0ck5!' -X POST 'https://idas.datameer.com/rest/job-execution?configuration='${ID}'' > pid.exe
		
		######Cleanup Routine; Also you can print it to a file before cleanup
		#cat pid.wbk pid.exe pid.ifg > Log.`date`.log
		#rm pid.wbk pid.exe pid.update.wbk Template1.wbk
		echo "Done Account: ${CustomerName}"
		sleep 1
done < AccountsInfo.csv
