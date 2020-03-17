#!/bin/bash

IFS=$'\n'
# echo ${TRUEUSERDOMAINS}
for user in $(cat /etc/trueuserdomains | awk -F: '{print substr($2,2)}'); do
    WP_THINGS=$(grep "wp-login.php\|wp-cron.php" /home/${user}/access-logs/* | wc -l)
    echo "${WP_THINGS} - ${user}"
done