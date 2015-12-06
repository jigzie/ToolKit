#!/bin/bash

flag=false; 
while IFS=, read blocks; 
do 
	if [[ $blocks =~ "/Applications/Work in Progress/Google Analytics/Data Imports/Google_Analytics_2012_02.upl" ]]; 
	then 
		flag="true" 
		echo "FOUND: $blocks"; 
	fi; if [[ $blocks =~ "id" && $flag == "true" ]]; then echo "ID: $blocks"; flag="false"; fi; done < IJ.ALL
