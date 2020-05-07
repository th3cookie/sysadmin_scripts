#!/bin/bash
# Usage -> bash <(curl https://raw.githubusercontent.com/th3cookie/sysadmin_scripts/master/bash/work/wp_attacks/web_attacks.sh) wp

if [ $# -ne 1 ]
then
    echo "Usage: $0 ARGUMENT"
    exit 1
fi

case "$1" in

wp) echo "Blocking top WP abusers by IP (Excluding Aus)..."
    # Checks top 20 wp hits this hour and blocks any attempts not from AUS with > 10 hits

    LOGS=$(grep -P '(wp-login|xmlrpc).*\"\ 200\ ' /usr/local/apache/domlogs/*/* | grep POST | grep $(date +%Y:%H) | cut -d " " -f 1 | cut -d ':' -f 2 | sort | uniq -c | sort -rn | head -n 20)
    echo "${LOGS}" | while read i; do
        COUNT=$(echo "${i}" | awk '{print $1}')
        IP=$(echo "${i}" | awk '{print $2}')
        GEO=$(geoiplookup ${i} | grep "Country Edition")
        echo -e "IP:\t\t\t\t\t${IP}"
        echo -e "Org Name:\t\t\t\t$(whois ${IP} | grep -P '[oO][rR][gG].{0,1}[nN][aA][mM][eE]' | head -n 1 | awk '{$1=""; print substr($0,2)}')"
        echo -e "Geoiplookup:\t\t\t\t${GEO}"
        echo -e "Count of hits: \t\t\t\t${COUNT}"
        if [[ ! "$GEO" =~ ([aA][uU][sS]) ]] && [[ ${COUNT} -gt 5 ]]
        then
            csf -d $IP "website attack"
        fi
        if [[ ${COUNT} -lt 5 ]]
        then
            echo "The rest have < 5 attempts, bailing the script..."
            exit 1
        fi
        echo -e "Last 10 logs:\n\n$(grep -r $IP /usr/local/apache/domlogs/ | grep POST | tail)\n\n-----------------------------------------------------------------------\n"
    done
    ;;

wpau) echo "Blocking top WP abusers by IP (including Aus)..."
    # Checks for most wp hits this hour and csf blocks top 20

    for i in $(grep "`date +%d/%b/%Y:%H:`" /usr/local/apache/domlogs/* | grep POST | grep -E 'xmlrpc|wp-login' | cut -d ':' -f 2 | awk '{ print $1 }' | sort | uniq -c | sort -nr | head -n 20 | awk '{print $2}'); do
        csf -d $i wpabuse
    done
    ;;

wpcron) echo  "Sending SIGQUIT signal"
    # This isn't used...

    IFS=$'\n'
    for user in $(cat /etc/trueuserdomains | awk -F: '{print substr($2,2)}'); do
        WP_THINGS=$(grep "wp-login.php\|wp-cron.php" /home/${user}/access-logs/* | wc -l)
        echo "${WP_THINGS} - ${user}"
    done
    ;;

*) echo "Argument $1 cannot be processed... Bailing..."
    exit 1
   ;;

esac
