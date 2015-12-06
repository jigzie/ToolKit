#!/bin/bash
Status="COMPLETED_WITH_WARNINGS"

if [[ "$Status" =~ "COMPLETED.*" ]]
then
	echo "Yes"
else
	echo "No"
fi;
