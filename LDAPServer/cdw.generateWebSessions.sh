#!/bin/bash
echo "Generating SQL insert for Orders Table";
set NewItemNumber="10";
rm CDW_WebSessions.sql;
for sessionID in {1..9}; 
do 
	for accountNumber in {1..1000};
	do
		for sessionDate in {1..7};
		do
			for itemNum in {100..300};
			do
				#echo "New Item Number; `expr 100 + $orderID` ";
				
				echo "INSERT INTO WEBSESSIONS VALUES ($sessionID, '2012-`expr $sessionDate + 1`-$sessionDate `expr $sessionID + $sessionDate`:$sessionID:$sessionDate', '$accountNumber', $itemNum);" >> CDW_WebSessions.sql;
			done
		done
	echo "Generated AccountNumber: $accountNumber";
	done
done
echo ""
echo "Done."
