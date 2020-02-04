#!/bin/bash
# Sami S - Hostopia AU
# Usage: Checks for IP addresses that are mostly causing load due to wp-loign or xmlrpc attacks. Blocks them on the hosts specified.
# Login to vc01 -> Click on a cluster that is having load issues -> VMs -> Sort by Host CPU.
# Click "Export" at the bottom and export the 'Name' and Host CPU rows to a CSV file.
# Copy/Paste the hosts from this file into the 'hosts_to_check.txt' file and run the script.

cat /dev/null > ips.txt
cat /dev/null > top_ips.txt

for i in $(cat hosts_to_check.txt); do
    echo "Processing ${i}..."
    ssh -T $i << EOF | grep -v login >> ips.txt
grep -P '(wp-login|xmlrpc).*\"\ 200\ ' /usr/local/apache/domlogs/*/* | grep POST | cut -d " " -f 1 | cut -d ':' -f 2 | sort | uniq -c | sort -n | tail -n 20
EOF
done

awk '{print $2}' ips.txt | sort | uniq -c | sort -n | tail -n 20 | awk '{print $2}' > top_ips.txt

echo -e "\nTop IP Addresses and geoiplookup of them, across the multiple hosts in hosts_to_check.txt file:\n"

for i in $(cat top_ips.txt); do
    echo -e "${i}\t-> $(geoiplookup ${i})"
done

read -r -p "Shall I proceed blocking the above IP addresses on the hosts in that file? [Y/N] " response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo '#!/bin/bash' > prep.sh
    for q in $(cat top_ips.txt); do
        echo "csf -d ${q} 'auto blocked by wp-attack script'" >> prep.sh
    done
    for i in $(cat hosts_to_check.txt); do
        cat prep.sh | ssh -T $i
    done
fi
