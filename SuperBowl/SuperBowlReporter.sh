#!/bin/bash
#Upload Script
###NOTES:
#### This script is to download the template: Workbook & Infographics to build a TAM Report view for each ACTIVE customer that has a TAM assigned.
####Logic/Algorithm of the script####
#1. Get the IDs of the workbooks/exportjobs
#2. Check Execution status: Status: Completed/Completed with Warnings/Failed (Failure needs to be notified as special request as well)
#3. Check the counters & parse as required OR just format in CSV (naming the file xls will open in excel)
#4. Append the results to a text file: Start Time, End Time, Duration=(End-Start)
#5. Iterate till list of IDs & complete email.
#6. Send Email.

IFS=$'\n'

echo "Name, JobStatus, StartTime, EndTime, Duration" > reportStatus.csv
while IFS=',' read ArtifactName ArtifactID ArtifactExeID
do
		echo "ArtifactName: $ArtifactName, ArtifactID: $ArtifactID, ArtifactExeID: $ArtifactExeID"
		echo "$username, $password, $serverIP, $serverPort, $protocol"
		#echo "http://localhost:8080/rest/job-configuration/job-history/$ArtifactID?start=0&length=1"
		curl -u admin:'admin' -X GET 'http://localhost:8080/rest/job-configuration/job-history/'${ArtifactID}'?start=0&length=1' > job.exe
		
		ExecutionID=$(cat job.exe | egrep -o "[0-9]+"| tr -d ' ')
		echo "${ArtifactExeID} and ${ExecutionID}"
		if [ "${ArtifactExeID}" -eq "${ExecutionID}" ]; then
			echo "$ArtifactName, \"NOT EXECUTED SINCE LAST RUN\"" >> reportStatus.csv
		else
			curl -u admin:'admin' -X GET 'http://localhost:8080/rest/job-execution/job-details/'${ExecutionID}'' > job.counters
		 
			startTime=$(cat job.counters| egrep -o "\"startTime\": (.*)" | egrep -o "\ .*"|sed 's/\"\,/\"/g'|tr -d ',')
			endTime=$(cat job.counters| egrep -o "\"stopTime\": (.*)" | egrep -o "\ .*"|sed 's/\"\,/\"/g'|tr -d ',')
			jobStatus=$(cat job.counters | egrep -o "\"jobStatus\": (.*)" | egrep -o "\ .*"|sed 's/\"\,/\"/g'|tr -d ',')

			echo "$ArtifactName, ${jobStatus}, ${startTime}, ${endTime}" >> reportStatus.csv
			######Cleanup Routine; Also you can print it to a file before cleanup
		fi
		echo "$ArtifactName,$ArtifactID,$ExecutionID" >> configFile.tmp
		#rm job.*
done < configFile
mv configFile.tmp configFile
#mail -s "SuperBow Report" jigz@datameer.com -f "reportStatus.csv"  < emailMessage 
#mail -s "SuperBow Report" jigz@datameer.com -f "emailMessage"  < emailMessage 
#echo "."
(cat emailMessage;uuencode reportStatus.csv reportStatus.csv) | mail -s "SuperBowlStatus" jigz@datameer.com
