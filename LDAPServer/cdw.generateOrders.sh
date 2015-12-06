#!/bin/bash
echo "Generating SQL insert for Orders Table";
set NewItemNumber="10";
rm CDW_orders.sql;
for orderID in {1..5}; 
do 
	for accountNumber in {1..1000};
	do
		for orderDate in {1..7};
		do
			for itemNum in {100..300};
			do
				#echo "New Item Number; `expr 100 + $orderID` ";
				#sleep 2;
				echo "INSERT INTO ORDERS VALUES ($orderID, '2012-`expr $orderDate + 1`-$orderDate `expr $orderID + $orderDate`:$orderID:$orderDate', '$accountNumber', $itemNum);" >> CDW_orders.sql;
			done
		done
	echo "Generated AccountNumber: $accountNumber";
	done
done
echo ""
echo "Done."
