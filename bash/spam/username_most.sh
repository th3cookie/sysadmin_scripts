#!/bin/bash
# Sami S - Hostopia AU 2019
# Usage -> bash <(curl https://raw.githubusercontent.com/th3cookie/sysadmin_scripts/master/bash/spam/username_most.sh)
# Currently not working yet. Have to iron it out.

exiqgrep -i | while read line; do
    BOUNCE=$(exim -bp | grep "${line}");
    echo "${BOUNCE}" | grep -q '<>'
    if [[ $? -eq 0 ]]; then
        MSG=$(grep ${MSGID} /var/log/exim_mainlog | awk '/<>/{print substr($6,3)}' | xargs -I {} zgrep {} /var/log/exim_mainlog)
        if [[ -z ${MSG} ]]; then
            MSG=$(zgrep ${MSGID} /var/log/exim_mainlog* | awk '/<>/{print substr($6,3)}' | xargs -I {} zgrep {} /var/log/exim_mainlog*)
        fi
    else
        MSG=$(grep ${MSGID} /var/log/exim_mainlog)
        if [[ -z ${MSG} ]]; then
            MSG=$(zgrep ${MSGID} /var/log/exim_mainlog*)
        fi
    fi
    USRNAME=$(echo "${MSG}" | grep 'U=' | awk -F 'U=' '{print $2}' | grep -v mailnull | awk '{print $1}' | head -n 1)
    if [[ -z "${USRNAME}" ]]; then
        USRNAME=$(echo "${MSG}" | grep "SpamAssassin as" | awk -F 'SpamAssassin as' '{print $2}' | awk '{print $1}' | head -n 1)
    fi
    if [[ -z "${DOMAIN}" ]] && [[ -n "${USRNAME}" ]]; then
        DOMAIN=$(grep ${USRNAME} /etc/trueuserdomains | awk -F: '{print $1}')
    fi
    echo $USRNAME;
    USRNAME="";
done | sort | uniq -c | sort -n