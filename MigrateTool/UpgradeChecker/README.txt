PLEASE READ THIS PRIOR to executing the script or uploading any artifacts.
Once you unzip the file you will have the following artifacts:
uploadDatameerConsumption.sh (script)
DatameerConsumption (folder): This contains further folders (connections, import-job, workbook, infographics) and *.json files underneath.

Do not use the json files directly as there are few redundant files.

#############
The uploadDatameerConsumption.sh script should have +x permission for the current user.

Modify the uploadDatameerConsumption.sh script for the following parameters
localhost: With the servername
8080: With datameer service port
admin:admin Replace this with valid user:password, if admin is disabled or modified


Execute:
./uploadDatameerConsumption.sh

#############
