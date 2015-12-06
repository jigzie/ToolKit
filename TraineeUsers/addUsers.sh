#!/bin/bash
#Upload Script
###NOTES:
##### Add user to training server
##### Update user password to training server
##### Maybe integrate with SFDC to somehow update

rm user.exe;
set customerName = "";
customerName = $1;
set expiryDate = "";
expiryDate = $2;

echo "Total args: $#"

###USAGE
if [ $# -ne 2 ]
then
	echo ""
        echo "Usage: ./addUsers.sh CustomerName ExpiryDate"
        echo "Usage: ./addUsers.sh AmericanAirlines 2014-12-27"
	echo ""
        exit 10
fi


while IFS=' ' read userID
do
	curl -u jigz:'D@t@m33r' -d '{username:"'${userID}'", email:"'${userID}@${customerName}'.com", roles : [Trainee], groups : ['${customerName}'], expires : "'${expiryDate}'"}' -X POST 'https://training.datameer.com/rest/user-management/users' >> user.exe
	echo "User Added: ${userID}" 
	curl -u jigz:'D@t@m33r' -d 'Datameer123' -X PUT 'https://training.datameer.com/rest/user-management/password/'${userID}''
	echo "User password set to default"
done < userNames
