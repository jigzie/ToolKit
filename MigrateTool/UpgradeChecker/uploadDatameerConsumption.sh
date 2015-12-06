#!/bin/bash

####This is to upload to the next server; same server will give error due to the existing artifacts
#READ the file names
#ids=( $(ls ${*/*.json) )
ids=( $(egrep "path.*Datameer Consumption Stats" DatameerConsumption/*/*.json | sed 's/:.*//') )
uniq=($(printf "%s\n" "${ids[@]}" | sort -u)); 
echo "${uniq[@]}"
for fileName in "${uniq[@]}"; do
       	echo "Adding Artifact: $fileName"
	artifactType=( $(echo "${fileName}" | sed 's/DatameerConsumption\///' | sed 's/\/.*//' | sed 's/ //g') ) 
	#echo "curl -u admin:admin -X POST -d @${fileName} 'http://localhost:2144/rest/'${artifactType}''"
       	curl -u admin:admin -X POST -d @$fileName 'http://localhost:2144/rest/'${artifactType}''
done
