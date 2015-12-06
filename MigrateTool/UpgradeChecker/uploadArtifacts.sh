#!/bin/bash

#This will upload all JSON files from the folders
####This is to upload to the next server; same server will give error due to the existing artifacts
#READ the file names
arrFiles=( $(ls ${*/*.json) )
for fileName in "${arrFiles[@]}"; do
       echo "Found File: $fileName"
       curl -u admin:admin -X POST -d @'$fileName' 'http://SERVER:8080/rest/'$fileName''
done

