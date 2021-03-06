# Find accounts using php the most
for i in {1..20}; do ps aux | grep php | awk '{print $1}' | sort | uniq -c | sort -n | awk '{print $2}' | tail >> ~/investigation.log; sleep 1; done; cat ~/investigation.log | sort | uniq -c | sort -n

# Most apache access log hits at a certain time, sorted (adjust search time variable)
SEARCH="26/May/2020:13:1[0-4]:"
# Current minute in real-time
SEARCH=$(date +%d/%b/%Y:%H:%M:)
for USER in $(awk -F\  '{print $2}' /etc/trueuserdomains); do echo "$(grep ${SEARCH} /home/$USER/access-logs/* 2> /dev/null | wc -l) - ${USER}"; done | sort -n

# Then to find the most endpoint hits at that time (update USER and SEARCH (above) variable with username and timestamp to search through logs)
USER="secretsales"
grep ${SEARCH} /home/$USER/access-logs/* 2> /dev/null | grep -oP "(?=(GET|POST)\ \K).*(?=\ HTTP)" | sort | uniq -c | sort -n

# Most mysql queries per DB
mysql -e "select DB from INFORMATION_SCHEMA.PROCESSLIST;" | awk /^DB$\|^information_schema$/'{ next; } {print $1}' | sort | uniq -c | sort -n

# Then if you want to tail the logs of the largest amount of mysql connections:
TOP_USER=$(mysql -e "select DB from INFORMATION_SCHEMA.PROCESSLIST;" | awk /^DB$\|^information_schema$/'{ next; } {print $1}' | sort | uniq -c | sort -n | tail -n 1 | awk '{print $2}' | awk -F '_' '{print $1}')
echo "Top user: ${TOP_USER}"; tail -f /home/${TOP_USER}*/access-logs/*