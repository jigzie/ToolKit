#!/bin/bash
###NOTES:
#### This script downloads a particular sheet data & then sends an email to a recipient/mailing address.
#### Steps:
#### a. Download the Data to a Folder under current Folder, maybe improve by having a local copy ALWAYS
#### b. Send an email as an attachment to the hard-coded value

#####USER CONFIGURATIONS##########
workbookId=5841;
sheetName="TimeSeries";
username="jigz";
#password="PUTYOUROWNDAMNPASSWORD";
serverAddress="https://idas.datameer.com";
##################################


#### Each TIME you run: Download the latest SFDC accounts information


#Download the Workbook Data for a particular sheet
curl -u $username:''${password}'' -X GET ''${serverAddress}'/rest/data/workbook/'${workbookId}'/'${sheetName}'/download' > Reports.csv

echo "Download Complete!!!"

mail -s "Test" -f "Reports.csv" jigz@datameer.com < emailMessage 
echo "."

