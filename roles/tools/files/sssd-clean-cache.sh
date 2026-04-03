#!/bin/bash

# Security: Ensure the script is executed by root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root."
  exit 1
fi

echo "Cleaning SSSD cache..."

# 1. First attempt to clean the cache gracefully
sss_cache -E

# 2. Stop the sssd service
systemctl stop sssd

# 3. Hard delete of the local cache
rm -rf /var/lib/sss/db/*

# 4. Start the sssd service
systemctl start sssd

echo "SSSD cache cleaned and service restarted."
