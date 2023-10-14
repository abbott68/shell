#!/bin/bash

# Check if correct number of arguments provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [Log File Path]"
    exit 1
fi

# Get argument
LOG_FILE="$1"

# Most Visited URLs
echo "Most Visited URLs:"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -5

# Most Active IP Addresses
echo -e "\nMost Active IP Addresses:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -5

# Other analyses can be added as per requirement
