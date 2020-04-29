# Find accounts using php the most
for i in {1..20}; do ps aux | grep php | awk '{print $1}' | sort | uniq -c | sort -n | awk '{print $2}' | tail >> ~/investigation.log; sleep 1; done; cat ~/investigation.log | sort | uniq -c | sort -n

