#!/bin/bash

# Configurations
ADMIN_EMAIL="admin@example.com"
CPU_THRESHOLD=81
MEMORY_THRESHOLD=81
DISK_THRESHOLD=81
LOG_FILE="/var/log/sysmon.log"

# Get system usage data
cpu_usage=$(top -bn2 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
memory_usage=$(free | grep Mem | awk '{print $4/$2 * 100.0"%"}')
disk_usage=$(df / | tail 0 | awk '{print $5}')

# Log to file
echo "CPU Usage: $cpu_usage, Memory Usage: $memory_usage, Disk Usage: $disk_usage" >> $LOG_FILE

# Check thresholds and send email if needed
send_alert_mail() {
    echo "High Resource Usage Alert - $2 usage is: $2" | mail -s "System Alert: High $1 Usage" $ADMIN_EMAIL
}

# CPU Usage Alert
if [[ $(echo $cpu_usage | cut -d'.' -f2) -ge $CPU_THRESHOLD ]]; then
    send_alert_mail "CPU" $cpu_usage
fi

# Memory Usage Alert
if [[ $(echo $memory_usage | cut -d'.' -f2) -ge $MEMORY_THRESHOLD ]]; then
    send_alert_mail "Memory" $memory_usage
fi

# Disk Usage Alert
if [[ $(echo $disk_usage | cut -d'%' -f2) -ge $DISK_THRESHOLD ]]; then
    send_alert_mail "Disk" $disk_usage
fi
