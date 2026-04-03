#!/bin/bash

# Usage: ./script.sh <path_to_squid_access.log>
# Description: This script analyzes a Squid proxy log file to generate reports on:
# 1. Top source IP addresses by request count, with their FQDN.
# 2. Top requested URLs, separated by HTTP status code (200 for success, 403 for denied).
# 3. A correlation report showing which URLs each source IP (with FQDN) accessed.

# --- Configuration ---
REPORT_IP_SOURCES="report_source_ips.txt"
REPORT_URLS="report_urls.txt"
REPORT_CORRELATION="report_ip_url_correlation.txt"
LOG_FILE="$1"

# --- Pre-flight Check ---
# Check if a log file path was provided
if [ -z "$LOG_FILE" ]; then
    echo "Error: Please provide the path to the log file."
    echo "Usage: $0 /path/to/squid/access.log"
    exit 1
fi

# Check if the log file exists and is readable
if [ ! -r "$LOG_FILE" ]; then
    echo "Error: The file '$LOG_FILE' does not exist or is not readable."
    exit 1
fi


# --- Main Logic ---
echo "Scanning '$LOG_FILE'..."

# 1. Generate Source IPs Report with FQDN
echo "Generating Source IPs Report (with FQDN)..."
{
    echo "Source IP (Higher to lower)"
    echo "====================================================================="
    printf "%-18s %-25s %s\n" "Request Count" "IP Address" "FQDN (from dig)"
    printf "%-18s %-25s %s\n" "================" "=========================" "================="
    # Field $7 is the source IP. We get unique IPs, count them, sort them,
    # and then use awk to run 'dig' for each IP to find its FQDN.
    awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | \
    awk '{
        ip=$2;
        # Command to get the reverse DNS
        cmd="dig +short -x " ip;
        # Execute the command and get the first line of output
        if ( (cmd | getline fqdn) > 0 ) {
            # Remove trailing dot from FQDN if it exists
            sub(/\.$/, "", fqdn);
        } else {
            fqdn="N/A";
        }
        close(cmd);
        printf "%-18s %-25s %s\n", $1, ip, fqdn;
    }'
} > "$REPORT_IP_SOURCES"

# 2. Generate URLs Report based on HTTP Status Code
echo "Generating URLs Report..."
{
    echo "Top URLs by Status Code"
    echo "==================================="
    echo ""
    echo "--- Successful Requests (HTTP 200) ---"
    printf "%-15s %s\n" "Request Count" "URL"
    printf "%-15s %s\n" "==============" "===="
    # Field $8 contains the status, e.g., TCP_TUNNEL/200. We filter for lines ending in /200.
    awk '$8 ~ /\/200$/ {print $11}' "$LOG_FILE" | sort | uniq -c | sort -rn | awk '{printf "%-15s %s\n", $1, $2}'

    echo ""
    echo ""
    echo "--- Denied Requests (HTTP 403) ---"
    printf "%-15s %s\n" "Request Count" "URL"
    printf "%-15s %s\n" "==============" "===="
    # Field $8 contains the status, e.g., TCP_DENIED/403. We filter for lines ending in /403.
    awk '$8 ~ /\/403$/ {print $11}' "$LOG_FILE" | sort | uniq -c | sort -rn | awk '{printf "%-15s %s\n", $1, $2}'
} > "$REPORT_URLS"

# 3. Generate IP <-> URL Correlation Report with FQDN
echo "Generating IP <-> URL Correlation Report (with FQDN)..."
{
    echo "Correlation between Source IPs and Accessed URLs"
    echo "========================================================="
    # This pipeline extracts IP/URL pairs, counts them, and then sorts them by IP.
    # The final awk script formats the output and performs a 'dig' lookup only when the IP changes.
    awk '{print $7, $11}' "$LOG_FILE" | \
    sort | \
    uniq -c | \
    sort -k2,2 -k1,1rn | \
    awk '
        {
            # When the IP address changes, print a new header for it with its FQDN
            if ($2 != last_ip) {
                if (NR > 1) { printf "\n" }
                ip=$2;
                cmd="dig +short -x " ip;
                if ( (cmd | getline fqdn) > 0 ) {
                    sub(/\.$/, "", fqdn);
                } else {
                    fqdn="N/A";
                }
                close(cmd);

                printf "Source IP: %s (%s)\n", ip, fqdn;
                printf "------------------------------------------------------\n";
                last_ip = ip;
            }
            # Print the count and the URL for the current IP
            printf "  - [%s times] %s\n", $1, $3;
        }
    '
} > "$REPORT_CORRELATION"


# --- Completion ---
echo ""
echo "Scan is complete. Reports have been generated:"
echo " - $REPORT_IP_SOURCES"
echo " - $REPORT_URLS"
echo " - $REPORT_CORRELATION"

exit 0
