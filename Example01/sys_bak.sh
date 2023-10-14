#!/bin/bash

# Check if correct number of arguments provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 [Source Directory] [Backup Directory] [Number of Backups to Keep]"
    exit 1
fi

# Get arguments
SOURCE_DIR="$1"
BACKUP_DIR="$2"
NUM_BACKUPS="$3"

# Create a new backup
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" -C "$SOURCE_DIR" .

# Delete old backups if exceeding $NUM_BACKUPS
cd "$BACKUP_DIR" || exit
BACKUPS_TO_DELETE=$(ls -1t | tail -n +$((NUM_BACKUPS + 1)))
if [ "$BACKUPS_TO_DELETE" != "" ]; then
    rm -f $BACKUPS_TO_DELETE
fi

echo "Backup completed!"
