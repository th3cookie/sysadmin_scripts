MSGID="1ijEtN-00E7fj-AC";
if [[ -z $MSGID ]]; then
    INVESTIGATE=$(exim -bp | awk -F '<' '/^ *[0-9]+/{print $2}' | cut -d '>' -f1 | sort | uniq -c | sort -n | grep -v $(facter fqdn) | tail -n 1 | awk '{print $2}')
    MSGID=$(exim -bp | grep -B 1 ${INVESTIGATE} | grep \< | awk '{print $3}' | tail -n 1)
fi
BOUNCE=$(exim -bp | grep "${MSGID}");
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

DOVEMETHOD=$(echo "${MSG}" | grep -oP 'dovecot_(plain|login)');
USRNAME=$(echo "${MSG}" | grep 'U=' | awk -F 'U=' '{print $2}' | grep -v mailnull | awk '{print $1}' | head -n 1);
if [[ -z $USRNAME ]]; then
    USRNAME=$(echo "${MSG}" | grep "SpamAssassin as" | awk -F 'SpamAssassin as' '{print $2}' | awk '{print $1}' | head -n 1)
else
    USRNAME="Cannot determine cpanel username!"
fi
MSGIP=$(echo "${MSG}" | grep "H=" | head -n 1 | grep -oP "(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))" | tail -n 1)
RETMSGIP=$?
if [[ -n ${DOVEMETHOD} ]]; then
    DOVERETURN=$(echo "${MSG}" | awk -v dove="$DOVEMETHOD" -F $DOVEMETHOD: '/dove/ {print $2}' | awk '{print $1}')
    SUBJECT=$(echo "${MSG}" | grep "T=" | head -n 1 | grep -oP "T=\".*\"" | cut -d '"' -f 2)
    echo -e "\nFull Logs:\n\n-------------------------------------------------------------------------------\n\n${MSG}\n\n-------------------------------------------------------------------------------\n"
    echo -e "Appears to be dovecot, the sending email is: ${DOVERETURN}"
    if [[ ${RETMSGIP} -eq 0 ]]; then
        echo -e "\nThe connecting IP was:\t\t${MSGIP}"
        echo -e "Geoiplookup of this IP:\t\t$(geoiplookup ${MSGIP})"
    fi
    echo -e "The Subject of the email was:\t${SUBJECT}\n"
    echo "Use this command to roll the password (only if you know it's compromised):"
    echo -e "/usr/local/cpanel/bin/uapi --user=${USRNAME} Email passwd_pop email=$(echo ${DOVERETURN} | awk -F '@' '{print $1}') password=$(openssl rand -base64 15) domain=$(echo ${DOVERETURN} | awk -F '@' '{print $2}')\n"
    echo -e "Send this to au-servicedesk-alerts:\nCan someone please get in touch with '"${USRNAME}"' on '$(facter fqdn)'\nCompromised email password has been rolled -> ${DOVERETURN}\n"
else
    echo -e "\nDid this return the right logs? (note it could be a bounceback)\n\n${MSG}"
    echo -e "\nIt's not dovecot, Checking for compromised scripts...\n"
    SCRIPTSITES=$(grep cwd /var/log/exim_mainlog | grep -v /var/spool | awk -F"cwd=" '{print $2}' | grep -vP ^$ | awk '{print $1}' | sort | uniq -c | sort -n | grep -v '\/tmp\/\|\/usr\/local\|\/etc\/csf\|\/root\|\/$' | tail)
    echo -e "${SCRIPTSITES}"
    echo "${SCRIPTSITES}" | while read line; do
        HOMEDIR=$(echo "${line}" | awk -F '/' '{print $3}' | grep -v ^$)
        COMCONTACT=$(grep POST /home/${HOMEDIR}/access-logs/* 2> /dev/null | grep 'com_contact' | awk '{print $7}' | sort -n | uniq -c | sort -n)
        if [[ -n ${COMCONTACT} ]]; then
            echo -e "\nThe following account has a potential joomla compromise:\n------------------------------"
            echo -e "Username ${HOMEDIR}:\n${COMCONTACT}";
            echo -e "\nEdit the htaccess with:\nvim $(echo ${line} | awk '{print $2}')/.htaccess"
            echo -e "\nSend this to au-servicedesk-alerts:\n\nCan someone get in touch with '"${HOMEDIR}"' on '$(facter fqdn)'\nCompromised joomla form on website '$(grep "${HOMEDIR}" /etc/trueuserdomains | awk -F: '{print $1}')' blocked in htaccess\nReseller Owner account name is '$(grep OWNER /var/cpanel/users/${HOMEDIR} | awk -F= '{print $2}')'\n------------------------------"
        fi
    done
    echo -e "\nCpanel username of the originating email is:\t${USRNAME}";
    echo -e "Domain for this account is: \t\t\t$(grep ${USRNAME} /etc/trueuserdomains | awk -F: '{print $1}')";
    if [[ ${RETMSGIP} -eq 0 ]]; then
        echo -e "Connecting IP sending to exim:\t\t\t${MSGIP}"
        echo -e "Geoiplookup of this IP:\t\t\t\t$(geoiplookup ${MSGIP})\n"
        echo -e "sample of script sending logs from the IP:\n$(grep ${MSGIP} /home/${USRNAME}/access-logs/* 2> /dev/null | tail)\n"
    fi
fi
