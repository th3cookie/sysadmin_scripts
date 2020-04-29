# Checks top 20 wp hits and gives you list of them with csf commands to block

LOGS=$(grep -P '(wp-login|xmlrpc).*\"\ 200\ ' /usr/local/apache/domlogs/*/* | grep POST | grep $(date +%Y:%H) | cut -d " " -f 1 | cut -d ':' -f 2 | sort | uniq -c | sort -n | tail -n 20)
echo "${LOGS}" | while read i; do
    COUNT=$(echo "${i}" | awk '{print $1}')
    IP=$(echo "${i}" | awk '{print $2}')
    GEO=$(geoiplookup ${i})
    echo -e "IP:\t\t\t\t\t${IP}"
    echo -e "Org Name:\t\t\t\t$(whois ${IP} | grep -P '[oO][rR][gG].{0,1}[nN][aA][mM][eE]' | head -n 1 | awk '{$1=""; print substr($0,2)}')"
    echo -e "Geoiplookup:\t\t\t\t${GEO}"
    echo -e "Count of hits: \t\t\t\t${COUNT}"
    echo -e "Block with: \t\t\t\tcsf -d $IP \"website attack\""
    echo -e "Last 10 logs:\n\n$(grep -r $IP /usr/local/apache/domlogs/ | tail)\n\n-----------------------------------------------------------------------\n"
done

-------------------------------------------------------------------------------------------------------------------------------------------------
# Checks for most wp hits this hour and csf blocks top 20

for i in $(grep "`date +%d/%b/%Y:%H:`" /usr/local/apache/domlogs/* | grep POST | grep -E 'xmlrpc|wp-login' | cut -d ':' -f 2 | awk '{ print $1 }' | sort | uniq -c | sort -nr | head -n 20 | awk '{print $2}'); do csf -d $i wpabuse; done

-------------------------------------------------------------------------------------------------------------------------------------------------

IFS=$'\n'
# echo ${TRUEUSERDOMAINS}
for user in $(cat /etc/trueuserdomains | awk -F: '{print substr($2,2)}'); do
    WP_THINGS=$(grep "wp-login.php\|wp-cron.php" /home/${user}/access-logs/* | wc -l)
    echo "${WP_THINGS} - ${user}"
done

-------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------