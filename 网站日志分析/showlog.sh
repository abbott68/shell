#!/bin/bash

# Read the log file

read -p "请输入读取日志的位置："  WeiZhi
logfile=$WeiZhi
#Count the number of lines
lines=$(wc -l $logfile | awk '{print $1}')
echo $lines

# Loop through each line
# Get the line line=head -$i $logfile | tail -1
# Extract the info we need
# for ((i=1; i<=$lines; i++)) 
# do 
#     timestamp= $(echo $lines | awk '{print $1}')
#     user= $(echo $lines | awk '{print $2}')
#     ip=$(echo $lines | awk '{print $3}')
#     action=$(echo $lines | awk '{print $4}')

#     # Print out the info
#     echo "Timestamp: $timestamp"
#     echo "User: $user"
#     echo "IP: $ip"
#     echo "Action: $action"
#     echo ""
# done