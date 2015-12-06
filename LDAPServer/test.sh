#!/bin/bash
for id in {101..117};
do
	result="";
	#echo "$id";
	result=`echo "$id" | grep -o '[0,2,4,6,8]$'`;
	#echo "RESULT:$result:"
	if [[ $result != "" ]];
	then
		echo "Even Number: $id $result number";
	else
		echo "NOT Even Number:$id number";
	fi;
	result="";
done
