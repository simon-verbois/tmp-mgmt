#!/bin/bash

# This script is used to determine which team, own which dns zone

# Usage
# bash dns_zone_owner.sh clients/2000/templates/dns

# Configuration
SEARCH_BASE="$1"
EMAIL_FROM="ict.linux@ebrc.com"
EMAIL_TO="linux.support@deep.eu"
EMAIL_SUBJECT="DNS Zones ownership"
EMAIL_BODY="Script result attached."

# Cleanup previous reports to avoid appending
rm -f *_zones_report.csv

# Find files, process with AWK, then loop through results
# AWK outputs: SCOPE|ZONE|TYPE|DATA
find "$SEARCH_BASE" -type f -exec awk '
    function get_scope(path) {
        if (match(path, /\/dns\/([^\/]+)\//, m)) { return m[1]; }
        return "unknown";
    }

    # Match zone definition
    /zone ".*" (IN )?\{/ {
        gsub(/"/, "", $2);
        zone = $2;
        scope = get_scope(FILENAME);
    }

    # Handle Master Zones
    /type master;/ && zone {
        print scope "|" zone "|MASTER|-"
    }

    # Handle Forward Zones
    /forwarders/ && zone {
        match($0, /\{([^}]+)\}/, arr);
        gsub(/[;]/, " ", arr[1]);
        print scope "|" zone "|FORWARD|" arr[1];
    }
' {} + | grep -v "\.arpa" | sort -u | while IFS="|" read -r scope zone type data; do

    # Define filename based on scope
    csv_file="${scope}_zones_report.csv"

    # Create file with headers if it doesn't exist yet
    if [[ ! -f "$csv_file" ]]; then
        echo "Zone Name,Type,Target IP,Target FQDN,Managing Team" > "$csv_file"
    fi

    if [[ "$type" == "MASTER" ]]; then
        echo "$zone,MASTER,N/A,Local File,ict-linux" >> "$csv_file"
    
    elif [[ "$type" == "FORWARD" ]]; then
        read -ra ips <<< "$data"
        fqdn=""
        final_ip=""

        # Try to resolve IPs until one works
        for ip in "${ips[@]}"; do
            if [[ -n "$ip" ]]; then
                check_fqdn=$(dig +short -x "$ip" | sed 's/\.$//')
                if [[ -n "$check_fqdn" ]]; then
                    fqdn="$check_fqdn"
                    final_ip="$ip"
                    break
                fi
            fi
        done

        if [[ -z "$final_ip" ]]; then final_ip="${ips[0]}"; fi
        
        team=""
        if [[ -z "$fqdn" ]]; then
            fqdn="Undefined FQDN"
            team="Undefined Team (No FQDN)"
        else
            # Convert FQDN to lowercase for pattern matching
            fqdn_lower="${fqdn,,}"

            if [[ "$fqdn_lower" =~ (lvu|lvp|lvd) ]]; then
                team="ict-linux"
            elif [[ "$fqdn_lower" =~ (wvp|wpp) ]]; then
                team="ict-mss"
            else
                team="Undefined Team"
            fi
        fi

        echo "$zone,FORWARD,$final_ip,$fqdn,$team" >> "$csv_file"
    fi

done

# Prepare email attachments
attachments=()
for report in *_zones_report.csv; do
    if [[ -f "$report" ]]; then
        attachments+=("-a" "$report")
    fi
done

# Send email if reports exist
if [[ ${#attachments[@]} -gt 0 ]]; then
    echo "$EMAIL_BODY" | /usr/bin/mail -r "$EMAIL_FROM" -s "$EMAIL_SUBJECT" "${attachments[@]}" "$EMAIL_TO"
    echo "Reports generated and sent."
else
    echo "No zones found, nothing sent."
fi


# Cleanup reports 
rm -f *_zones_report.csv