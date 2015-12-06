#!/bin/bash
#This script is to send email to the CSM on regular schedule
#Current Schedule: 
#WEEKLY: RED Accounts
#BI-WEEKLY: YELLOW
#MONTHLY: GREEN
#v1: Just send email to ALL ID's identified, no check on Red/Yellow/Green
#v2: Add logic for Red/Yellow/Green; so you'll need to maintain lastRun information

###Perform a read on the file & only use the ones where you have CSM Email address
IFS=$'\n'

currentDate = date +"%d-%b-%Y"
while IFS='|' read workbookID customer CSMEmail
do
	clear
	if [ "${CSMEmail}" == "" ]; then
		#No CSM to email then skip this record.
		#Later add the notify admin for fixing this.
		echo "Skipping workbook ID: ${workbookID} as no CSMEmail found."
		continue
	fi
		###Start building Email
		rm EmailReport.html
		rm CustomerReport.html
		echo "Building Email Report for: ${customer}"
		###Common header information for Customer
		cat CustomerEmail.header |sed 's/CUSTOMER/'${customer}'/g'  > EmailReport.html.tmp
	
		#echo "<b>Datameer bugs FIXED for ${customer}</b>" >> EmailReport.html	
		echo "<h3 style=\"color:#2D79B1\" align=\"center\">Datameer bugs FIXED for ${customer}</h3>" >> EmailReport.html
		echo "<table class=\"info\" width=\"100%\" border=\"1\" cellspacing=\"0\" cellpadding=\"0\" style=\"max-width:600px; border: 1px solid #dfdfdf;\">" >> EmailReport.html
		###Download the FIXED BUGS from workbook
		###Append to email
		curl -u jigz:'D@t@m33rR0ck5!' -X GET 'https://idas.datameer.com/rest/data/workbook/'${workbookID}'/FixedRequestEmailReport/download' > Fixed.csv
		#First line=Header
		head -n 1 Fixed.csv > Fixed.header
		#Rest is data
		awk 'NR>1' Fixed.csv > Fixed.report
		cat Fixed.header | sed 's/\"\,\"/\|/g' |sed 's/\"//g' > Fixed.header.tmp
		cat Fixed.report | sed 's/\"\,\"/\|/g' |sed 's/\"//g' > Fixed.report.tmp

		mv Fixed.header.tmp Fixed.header
		mv Fixed.report.tmp Fixed.report

		cat  Fixed.header | awk -F"\|" '{print "<tr><th scope=\"col\">"$1"</th> <th scope=\"col\">"$2"</th><th scope=\"col\">"$3"</th><th scope=\"col\">"$4"</th><th scope=\"col\">"$5"</th></tr>"}' >> EmailReport.html
		cat  Fixed.report | awk -F"\|" '{print "<tr><td align=\"center\">"$1"</td> <td align=\"center\">"$2"</td><td align=\"center\">"$3"</td><td align=\"center\">"$4"</td><td align=\"center\">"$5"</td></tr>"}' >> EmailReport.html
		echo "</table>" >> EmailReport.html
                #rm Fixed.header Fixed.report Fixed.report.tmp Fixed.csv

		###Download the New & Noteworthy form workbook
		###Append to email
		curl -u jigz:'D@t@m33rR0ck5!' -X GET 'https://idas.datameer.com/rest/data/workbook/'${workbookID}'/EmailReport/download' > New_Noteworthy.csv
		#echo "<p style=\"font-size:15px; color:#2D79B1\">" >> EmailReport.html 
		echo "<h3 style=\"color:#2D79B1\" align=\"center\">New & Noteworthy Features</h3>" >> EmailReport.html
		echo "<table class=\"info\" width=\"100%\" border=\"1\" cellspacing=\"0\" cellpadding=\"0\" style=\"max-width:600px; border: 1px solid #dfdfdf;\">" >> EmailReport.html

		head -n 1 New_Noteworthy.csv > New_Noteworthy.header
		awk 'NR>1' New_Noteworthy.csv > New_Noteworthy.report
		
		cat New_Noteworthy.header | sed 's/\"\,\"/\|/g' |sed 's/\"//g' > New_Noteworthy.header.tmp
                cat New_Noteworthy.report | sed 's/\"\,\"/\|/g' |sed 's/\"//g' > New_Noteworthy.report.tmp

		mv New_Noteworthy.header.tmp New_Noteworthy.header
                mv New_Noteworthy.report.tmp New_Noteworthy.report

		cat New_Noteworthy.header | awk -F"\|" '{print "<tr><th scope=\"col\">"$1"</th><th scope=\"col\">"$2"</th></tr>"}' >> EmailReport.html
		#awk 'NR>1' New_Noteworthy.csv | sed 's/\"\,\"/\|/g'| sed 's/\"//g' > New_Noteworthy.report 
	
		###ADDING NEW & NOTEWORTHY DETAILS for this customer.
		cat  New_Noteworthy.report | awk -F"\|" '{print "<tr><td align=\"center\">"$1"</td><td align=\"center\">"$2"</td></tr>"}' >> EmailReport.html 
		#echo "</p></pre>" >> EmailReport.html
		#echo "<table border=\"1\">" >>  EmailReport.html
		echo "</table>" >> EmailReport.html           
		#echo "</p>" >> EmailReport.html
		#cat CustomerEmail.footer >> EmailReport.html
		#echo "</body></html>" >> EmailReport.html
	
		
	  	echo `cat EmailReport.html.tmp ` >> CustomerReport.html
		echo `cat EmailReport.html` >> CustomerReport.html
		echo `cat CustomerEmail.footer` >> CustomerReport.html
		sleep 3;

##SEND EMAIL; DO NOT CHANGE THE BELOW format or ADD TAB for formatting, it breaks the sendEmail format
cat - CustomerReport.html <<EOF| sendmail -oi -t
From: CSMReport@datameer.com
To: `echo ${CSMEmail}` 
Subject: Datameer Report: `echo ${customer} ${currentDate}`  
Content-Type: text/html; charset=us-ascii
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
EOF

rm Fixed.*
rm New_Noteworthy*
rm EmailReport.html*
done < WbkIDs.list
