#!/bin/bash
start=$(date -d "$(date +'%Y')-01-01" +%s)
end=$(date +%s)
echo "Days since begining of the year: $(( ($end - $start) / 86400 ))"
echo "Seconds since epoch: $end"
