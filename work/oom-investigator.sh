#!/bin/bash
# This script will only work if searching the day of the oom. No historic apache access logs available.

# Grab the log line to investigate apache access logs
TIME_LOG=$(grep -i oom /var/log/messages | tail)
# If the above is empty, go through the gzipped log of yesterdays messages to find an OOM.
[[ -z $TIME_LOG ]] && TIME_LOG=$(zgrep -ih oom /var/log/messages-$(date +%Y%m%d).gz | tail -n 1)

# Grab the variables we will need to go through apache access logs
TIME_LOG_MONTH=$(echo $TIME_LOG | awk '{print $1}')
TIME_LOG_DAY=$(echo $TIME_LOG | awk '{print $2}')
TIME_LOG_TIME=$(echo $TIME_LOG | awk '{print $3}')
TIME_LOG_YEAR=$(date +%Y)

# Preparing search query
SEARCH="${TIME_LOG_DAY}/${TIME_LOG_MONTH}/${TIME_LOG_YEAR}:${TIME_LOG_TIME}"

# Go for it
grep ${SEARCH} /usr/local/apache/domlogs/*/*
