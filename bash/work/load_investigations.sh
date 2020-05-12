# Find accounts using php the most
for i in {1..20}; do ps aux | grep php | awk '{print $1}' | sort | uniq -c | sort -n | awk '{print $2}' | tail >> ~/investigation.log; sleep 1; done; cat ~/investigation.log | sort | uniq -c | sort -n

# Most apache access log hits at a certain time, sorted
for user in $(awk -F\  '{print $2}' /etc/trueuserdomains); do echo "$(grep 29/Apr/2020:03:2[5-8]: /home/$user/access-logs/* 2> /dev/null | wc -l) - ${user}"; done | sort -n

# Most mysql queries per DB
mysql -e "select DB from INFORMATION_SCHEMA.PROCESSLIST;" | awk /^DB$\|^information_schema$/'{ next; } {print $1}' | sort | uniq -c | sort -n

# Then if you want to tail the logs of the largest amount of mysql connections:
tail -f /home/$(mysql -e "select DB from INFORMATION_SCHEMA.PROCESSLIST;" | awk /^DB$\|^information_schema$/'{ next; } {print $1}' | sort | uniq -c | sort -n | tail -n 1 | awk '{print $2}' | awk -F '_' '{print $1}')*/access-logs/*