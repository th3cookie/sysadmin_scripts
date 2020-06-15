#!/bin/bash
# Usage -> MSGID="1jEIff-008TY2-QR"; bash <(curl https://raw.githubusercontent.com/th3cookie/sysadmin_scripts/master/work/email_spam/spam_checker.sh) $MSGID
# Usage 2 -> MSGID="1itJK6-004Keg-O7"; wget https://raw.githubusercontent.com/th3cookie/sysadmin_scripts/master/work/email_spam/spam_checker.sh -O ~/chk_spam.sh && chmod +x ~/chk_spam.sh; ~/chk_spam.sh $MSGID

MSGID="$1";
if [[ -z $MSGID ]]; then
    INVESTIGATE=$(exim -bp | awk -F '<' '/^ *[0-9]+/{print $2}' | cut -d '>' -f1 | sort | uniq -c | sort -n | grep -v $(facter fqdn) | tail -n 1 | awk '{print $2}')
    MSGID=$(exim -bp | grep -B 1 ${INVESTIGATE} | grep \< | awk '{print $3}' | tail -n 1)
fi
BOUNCE=$(exim -bp | grep "${MSGID}");
echo "${BOUNCE}" | grep -q '<>'
if [[ $? -eq 0 ]]; then
    echo -e "\nThis message was a bounceback. Tracing it back to it's source..."
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
DOVEMETHOD=$(echo "${MSG}" | grep -oP 'dovecot_(plain|login)')
EMAIL=$(echo "${MSG}" | awk -v dove="$DOVEMETHOD" -F $DOVEMETHOD: '/dove/ {print $2}' | awk '{print $1}')
SUBJECT=$(echo "${MSG}" | grep "T=" | head -n 1 | grep -oP "T=\".*\"" | cut -d '"' -f 2)
MSGIP=$(echo "${MSG}" | grep "H=" | head -n 1 | grep -oP "(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))" | tail -n 1)
RETMSGIP=$?
DOMAIN=$(echo ${EMAIL} | awk -F '@' '{print $2}')
USRNAME=$(echo "${MSG}" | grep 'U=' | awk -F 'U=' '{print $2}' | grep -v mailnull | awk '{print $1}' | head -n 1)
if [[ -z "${USRNAME}" ]]; then
    USRNAME=$(echo "${MSG}" | grep "SpamAssassin as" | awk -F 'SpamAssassin as' '{print $2}' | awk '{print $1}' | head -n 1)
fi
if [[ -z "${DOMAIN}" ]] && [[ -n "${USRNAME}" ]]; then
    DOMAIN=$(grep ${USRNAME} /etc/trueuserdomains | awk -F: '{print $1}')
fi
if [[ -z "${USRNAME}" ]] && [[ -n "${DOMAIN}" ]]; then
    USRNAME=$(grep "${DOMAIN}" /etc/trueuserdomains | awk -F ':' '{print substr($2,2)}')
fi
if [[ ${USRNAME} =~ __cpanel__service__auth.* ]]; then
    DOMAIN=$(echo "${MSG}" | grep -oP '(cpanel@(\w*\.*)*)' | head -n 1 | awk -F '@' '{print $2}')
    USRNAME=$(grep "${DOMAIN}" /etc/trueuserdomains | awk -F ':' '{print substr($2,2)}')
fi
RESELLER=$(grep OWNER /var/cpanel/users/${USRNAME} | awk -F= '{print $2}')
echo -e "\nFull Logs for Message ID '${MSGID}':\n\n-------------------------------------------------------------------------------\n\nDid this return the right logs? (note it could be a bounceback)\n\n${MSG}\n\n-------------------------------------------------------------------------------\n"
echo -e "Cpanel username of the originating email is:\t${USRNAME}";
echo -e "Domain for this account is: \t\t\t${DOMAIN}";
echo -e "The Subject of the email was:\t\t\t${SUBJECT}\n"
if [[ ${RETMSGIP} -eq 0 ]]; then
    echo -e "Connecting IP sending to exim:\t\t\t${MSGIP}"
    echo -e "Geoiplookup of this IP:\t\t\t\t$(geoiplookup ${MSGIP} | head -n 1)\n"
fi
if [[ -n ${DOVEMETHOD} ]]; then
    if [[ $SUBJECT =~ "SSL Pending Queue" ]]; then
        echo -e "Appears to be a broken SSL queue for username '${USRNAME}'. Use this commands to roll the SSL and clear exim for this user:"
        echo -e "mv -v /home/${USRNAME}/.cpanel/ssl/pending_queue.json{,.old}"
        echo -e "exim -bp | grep -B 1 ${DOMAIN} | grep \< | awk '{print \$3}' | xargs exim -Mrm\n"
    else
        echo -e "Appears to be dovecot, the sending email is: ${EMAIL}"
        echo "Use this command to roll the password (only if you know it's compromised):"
        echo -e "/usr/local/cpanel/bin/uapi --user=${USRNAME} Email passwd_pop email=$(echo ${EMAIL} | awk -F '@' '{print $1}') password=$(openssl rand -base64 15) domain=$(echo ${EMAIL} | awk -F '@' '{print $2}')\n"
        echo "Send this to l1-newbies:"
        echo "Can someone please get in touch with '"${USRNAME}"' on '$(hostname)'"
        echo "Compromised email password has been rolled -> ${EMAIL}"
        if [[ ! $RESELLER =~ (dpresell|shared) ]]; then
            echo -e "Reseller Owner account name is '${RESELLER}'\n--------------------------------------------------"
        fi
    fi
else
    echo -e "It's not dovecot, Checking for compromised scripts...\n"
    SCRIPTSITES=$(grep cwd /var/log/exim_mainlog | grep -v /var/spool | awk -F"cwd=" '{print $2}' | grep -vP ^$ | awk '{print $1}' | sort | uniq -c | sort -n | grep -v '\/tmp\/\|\/usr\/local\|\/etc\/csf\|\/root\|\/$' | tail)
    echo -e "${SCRIPTSITES}\n"
    echo -e "Checking Username '${USRNAME}' for the most POST requests in apache logs (last 20).\nPlease investigate the below manually...\n"
    POSTLOGS=$(grep POST /home/${USRNAME}/access-logs/* | awk '{print $7}' | sort -n | uniq -c | sort -n | tail -n 20)
    echo "$POSTLOGS" | while read line; do
        CT=$(echo $line | awk '{print $1}')
        echo -e "${CT}\t->\t${DOMAIN}$(echo $line | awk '{print $2}')"
    done
    # Doing Joomla Checks
    echo "${SCRIPTSITES}" | while read line; do
        HOMEDIR=$(echo "${line}" | awk -F '/' '{print $3}' | grep -v ^$)
        COMCONTACT=$(grep POST /home/${HOMEDIR}/access-logs/* 2> /dev/null | grep 'com_contact' | awk '{print $7}' | sort -n | uniq -c | sort -n)
        if [[ -n ${COMCONTACT} ]]; then
            echo -e "\nThe following account has a potential joomla compromise:\n--------------------------------------------------------"
            echo -e "Username ${HOMEDIR}:\n${COMCONTACT}";
            echo -e "\nEdit the htaccess with:\nvim $(echo ${line} | awk '{print $2}')/.htaccess"
            echo -e "Put this in the htaccess:\n"
            cat << EOF
# Joomla contact form blocked by <COMPANY> due to email abuse - $(date +%d/%m/%Y)
RewriteCond %{QUERY_STRING} !^/?option=
RewriteRule .? - [S=2]
RewriteCond %{QUERY_STRING} !/?option=([a-z0-9_]+)&view=.* [NC]
RewriteRule .? - [R=403]
RewriteCond %{QUERY_STRING} /?option=com_contact [NC]
RewriteRule .? - [R=403]
EOF
            echo -e "\nSend this to l1-newbies:"
            echo "Can someone get in touch with '"${HOMEDIR}"' on '$(hostname)'"
            echo "Compromised joomla form on website '$(grep "${HOMEDIR}" /etc/trueuserdomains | awk -F: '{print $1}')' blocked in htaccess"
            if [[ ! $RESELLER =~ (dpresell|shared) ]]; then
                echo -e "Reseller Owner account name is '${RESELLER}'"
            fi
            echo "--------------------------------------------------------"
        fi
    done
    # echo -e "sample of script sending logs from the IP:\n$(grep ${MSGIP} /home/${USRNAME}/access-logs/* 2> /dev/null | tail)\n"
    if [[ ${HOMEDIR} != ${USRNAME} ]]; then
        echo -e "\nSend this to l1-newbies:"
        echo -e "Can someone get in touch with '"${USRNAME}"' on '$(hostname)'"
        echo -e "Compromised form on website '${DOMAIN}' is sending spam - blocked in htaccess"
        if [[ ! $RESELLER =~ (dpresell|shared) ]]; then
            echo -e "Reseller Owner account name is '${RESELLER}'\n------------------------------"
        fi
    fi
fi
echo -e "\nClear the exim queue with:"
if [[ ! $(exim -bp | grep ${MSGID} | grep '<>') ]] && [[ -n ${EMAIL} ]]; then
    echo "exim -bp | awk '/${EMAIL}/{print \$3}' | xargs exim -Mrm"
else
    echo "exim -bp | awk '/<>/{print \$3}' | xargs exim -Mrm"
fi
echo ""
