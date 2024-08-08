#!/bin/bash

bill=()
v=0

while read line; do
        if [[ $(echo "$line" | awk '{print $1}') == "Timestamp" ]]; then
                continue
        fi
        status=$(echo "$line" | awk '{print $7}')
        status="${status//[$'\t\r\n ']}"
        if [[ "$status" == "Unbilled" ]]; then
                username=$(echo "$line" | awk '{print $3}')
                total_usage=$(($(echo "$line" | awk '{print $5}') + $(echo "$line" | awk '{print $6}')))
                total_bill=$(echo "$total_usage*0.05" | bc)
                touch temp1.txt
                echo "$username $total_bill" >> temp1.txt
        fi
        if [[ "$status" == "Billed" ]]; then
                username=$(echo "$line" | awk '{print $3}')
                total_usage=$(($(echo "$line" | awk '{print $5}') + $(echo "$line" | awk '{print $6}')))
                echo "$username 0" >> temp1.txt
        fi
done < network_usage.log

while read line; do
        if [[ $(echo "$line" | awk '{print $1}') == "Timestamp" ]]; then
                continue
        fi
        username=$(echo "$line" | awk '{print $3}')
        touch $username-temp.txt
        awk -v username="$username" '$1 == username {print $2}' temp1.txt > $username-temp.txt
done < network_usage.log

total_unbilled_amount=0
for _username in $(ls -A *-temp.txt); do
        username=${_username:0:-9}
        total_bill=0
        while read bill; do
                bill="${bill//[$'\t\r\n ']}"
                total_bill=$(echo "$total_bill + $bill" | bc)
        done < $username-temp.txt
        total_billed["$username"]=$total_bill
        echo "$username $total_bill" >> temp-last.txt
        total_unbilled_amount=$(echo "$total_unbilled_amount + $total_bill" | bc)

done
echo "The total amount due is $total_unbilled_amount"

rm network_bills.txt
touch network_bills.txt

sort -k 2 -r temp-last.txt > network_bills.txt

rm top-3-unbilled.txt
touch top-3-unbilled.txt

for i in {1..3}; do
        username=$(awk -v line=$i 'NR == line {print $1}' network_bills.txt)
        echo "$username:" >> top-3-unbilled.txt
        echo "    total-usage: $(echo "${total_billed[$username]} * 20" | bc)" >> top-3-unbilled.txt
        echo "    total-bill: ${total_billed[$username]}" >> top-3-unbilled.txt
        echo "" >> top-3-unbilled.txt
        echo "Timestamp IP_Adress Downloaded_data Uploaded_data Billing_status" >> top-3-unbilled.txt
        echo "" >> top-3-unbilled.txt
        awk -v username="$username" '$3 == username {print "    " $0}' network_usage.log >> top-3-unbilled.txt
        echo "" >> top-3-unbilled.txt
done


rm temp*
rm *-temp.txt
